Bitmap在Android4.0之后将Bitmap的内存从Native层转移到Java层了。
在Java层，创建一个Bitmap对象需要使用Bitmap的createBitmap的系列方法,Bitmap通过下面的方法来时创建Bitmap对象。
```
private static Bitmap createBitmap(DisplayMetrics display, int width, int height,
            Config config, boolean hasAlpha) {
        if (width <= 0 || height <= 0) {
            throw new IllegalArgumentException("width and height must be > 0");
        }
        Bitmap bm = nativeCreate(null, 0, width, width, height, config.nativeInt, true);
        if (display != null) {
            bm.mDensity = display.densityDpi;
        }
        bm.setHasAlpha(hasAlpha);
        if (config == Config.ARGB_8888 && !hasAlpha) {
            nativeErase(bm.mFinalizer.mNativeBitmap, 0xff000000);
        }
        // No need to initialize the bitmap to zeroes with other configs;
        // it is backed by a VM byte array which is by definition preinitialized
        // to all zeroes.
        return bm;
    }

```
上面代码位于framework/base/core/graphics/java/android/graphics/Bitmap.java

在createBitmap方法中通过nativeCreate方法来创建Bitmap对象，nativeCreate方法的申明如下：
```
private static native Bitmap nativeCreate(int[] colors, int offset,
                                              int stride, int width, int height,
                                              int nativeConfig, boolean mutable);
```
nativeCreate的参数colors是像素点颜色数组，offset是数组的起始偏移量，stride是每个像素颜色的跨越值，width是bitmap 的宽度值，height是bitmap 的高度值，nativeConfig是Config的int值，Config是一个枚举类型，代码下面列出，nativeConfigInt也就是config对象的int型表示。
```
public enum Config {
        // these native values must match up with the enum in SkBitmap.h

        ALPHA_8     (1),

        RGB_565     (3),

        @Deprecated
        ARGB_4444   (4),

        ARGB_8888   (5);

        final int nativeInt;

        private static Config sConfigs[] = {
            null, ALPHA_8, null, RGB_565, ARGB_4444, ARGB_8888
        };

        Config(int ni) {
            this.nativeInt = ni;
        }

        static Config nativeToConfig(int ni) {
            return sConfigs[ni];
        }
    }
```
nativeCreate在Native层对应的方法是framework/base/core/jni/android/graphics/Bitmap.cpp文件中的Bitmap_creator方法中。
```
static jobject Bitmap_creator(JNIEnv* env, jobject, jintArray jColors,
                              jint offset, jint stride, jint width, jint height,
                              jint configHandle, jboolean isMutable) {
    SkColorType colorType = GraphicsJNI::legacyBitmapConfigToColorType(configHandle);
    if (NULL != jColors) {
        size_t n = env->GetArrayLength(jColors);
        if (n < SkAbs32(stride) * (size_t)height) {
            doThrowAIOOBE(env);
            return NULL;
        }
    }

    // ARGB_4444 is a deprecated format, convert automatically to 8888
    if (colorType == kARGB_4444_SkColorType) {
        colorType = kN32_SkColorType;
    }

    SkBitmap bitmap;
    bitmap.setInfo(SkImageInfo::Make(width, height, colorType, kPremul_SkAlphaType));

    Bitmap* nativeBitmap = GraphicsJNI::allocateJavaPixelRef(env, &bitmap, NULL);
    if (!nativeBitmap) {
        return NULL;
    }

    if (jColors != NULL) {
        GraphicsJNI::SetPixels(env, jColors, offset, stride,
                0, 0, width, height, bitmap);
    }

    return GraphicsJNI::createBitmap(env, nativeBitmap,
            getPremulBitmapCreateFlags(isMutable));
}
```
这里首先调用GraphicsJNI::legacyBitmapConfigToColorType将configHandle转换成SkColorType,configHandle是Java层的Config对象的int型表示，legacyBitmapConfigToColorType函数如下：
```
SkColorType GraphicsJNI::legacyBitmapConfigToColorType(jint legacyConfig) {
    const uint8_t gConfig2ColorType[] = {
        kUnknown_SkColorType,
        kAlpha_8_SkColorType,
        kIndex_8_SkColorType,
        kRGB_565_SkColorType,
        kARGB_4444_SkColorType,
        kN32_SkColorType
    };

    if (legacyConfig < 0 || legacyConfig > kLastEnum_LegacyBitmapConfig) {
        legacyConfig = kNo_LegacyBitmapConfig;
    }
    return static_cast<SkColorType>(gConfig2ColorType[legacyConfig]);
}
```
之后colors数组不为NULL的话，检查colors数组的合法性，如果colors的长度小于stride*height，说明colors数组中要跳过的数大于数组的长度，也就是colors数组中没有合法的像素值。如果colors数组是合法的，则继续执行。
```
	SkBitmap bitmap;
    bitmap.setInfo(SkImageInfo::Make(width, height, colorType, kPremul_SkAlphaType));
```
```
	SkImageInfo()
        : fWidth(0)
        , fHeight(0)
        , fColorType(kUnknown_SkColorType)
        , fAlphaType(kUnknown_SkAlphaType)
        , fProfileType(kLinear_SkColorProfileType)
    {}

    static SkImageInfo Make(int width, int height, SkColorType ct, SkAlphaType at,
                            SkColorProfileType pt = kLinear_SkColorProfileType) {
        return SkImageInfo(width, height, ct, at, pt);
    }
```
SkImageInfo定义在external/skia/include/core/SkImageInfo.h文件中
创建一个SkBitmap对象，调用SkImageInfo::Make方法通过从Java层传下来的width，height以及上面转换得到的colorType，以及kPremul_SkAlphaType来得到一个SkBitmapInfo对象，kPremul_SkAlphaType是一个SkAlphaType类型，
```
enum SkAlphaType {
	//All pixels are stored as opaque
    kUnknown_SkAlphaType,

    kOpaque_SkAlphaType,

    kPremul_SkAlphaType,

    kUnpremul_SkAlphaType,

    kLastEnum_SkAlphaType = kUnpremul_SkAlphaType
};
```
之后调用SkBitmap.setInfo将得到SkImageInfo记录下来。调用GraphicsJNI::allocateJavaPixelRef方法，此方法是用于在Java层给Bitmap对象分配内存。该方法实现位于framework/base/jni/android/graphics/Graphics.cpp文件中：
```
android::Bitmap* GraphicsJNI::allocateJavaPixelRef(JNIEnv* env, SkBitmap* bitmap,
                                             SkColorTable* ctable) {
    const SkImageInfo& info = bitmap->info();
    if (info.fColorType == kUnknown_SkColorType) {
        doThrowIAE(env, "unknown bitmap configuration");
        return NULL;
    }

    size_t size;
    if (!computeAllocationSize(*bitmap, &size)) {
        return NULL;
    }

    // we must respect the rowBytes value already set on the bitmap instead of
    // attempting to compute our own.
    const size_t rowBytes = bitmap->rowBytes();

    jbyteArray arrayObj = (jbyteArray) env->CallObjectMethod(gVMRuntime,
                                                             gVMRuntime_newNonMovableArray,
                                                             gByte_class, size);
    if (env->ExceptionCheck() != 0) {
        return NULL;
    }
    SkASSERT(arrayObj);
    jbyte* addr = (jbyte*) env->CallLongMethod(gVMRuntime, gVMRuntime_addressOf, arrayObj);
    if (env->ExceptionCheck() != 0) {
        return NULL;
    }
    SkASSERT(addr);
    android::Bitmap* wrapper = new android::Bitmap(env, arrayObj, (void*) addr,
            info, rowBytes, ctable);
    wrapper->getSkBitmap(bitmap);
    // since we're already allocated, we lockPixels right away
    // HeapAllocator behaves this way too
    bitmap->lockPixels();

    return wrapper;
}
```
在这个方法中，首先info的fColorType和kUnknown_SkColorType相等的话，表示要创建的Bitmap的colorType是错误的，方法返回。否则继续执行，计算需要分配的大小，如果大小等于0，就不需要创建，直接返回。不等于0的话，通过调用jni的CallObjectMethod来调用gVimRuntime的gVMRuntime_newNonMovableArray方法来创建一个数组，这个数组类型和长度分别用gByte_class和size表示。CallObjectMethod函数返回一个jbyteArray，此时，在Java层已经创建了一个长度为size的byte数组。

数组创建完毕后，通过调用jni的CallLongMethod方法调用gVMRuntime对象的gVMRuntime_addressOf方法来获取上面的到arrayObj的数组地址。

得到数组地址后，创建一个Native层的Bitmap对象wrapper，调用wrapper的getSkBitmap方法为bitmap设置了一些参数。
```
void Bitmap::getSkBitmap(SkBitmap* outBitmap) {
    assertValid();
    android::AutoMutex _lock(mLock);
    // Safe because mPixelRef is a WrappedPixelRef type, otherwise rowBytes()
    // would require locking the pixels first.
    outBitmap->setInfo(mPixelRef->info(), mPixelRef->rowBytes());
    outBitmap->setPixelRef(refPixelRefLocked())->unref();
    outBitmap->setHasHardwareMipMap(hasHardwareMipMap());
}
```
调用SkBitmap对象bitmap的lockPixels方法锁定像素数据后，GraphicsJNI::allocateJavaPixelRef函数返回wrapper对象，回到Bitmap_creator方法。
```
static jobject Bitmap_creator(JNIEnv* env, jobject, jintArray jColors,
                              jint offset, jint stride, jint width, jint height,
                              jint configHandle, jboolean isMutable) {
    ......

    Bitmap* nativeBitmap = GraphicsJNI::allocateJavaPixelRef(env, &bitmap, NULL);
    if (!nativeBitmap) {
        return NULL;
    }

    if (jColors != NULL) {
        GraphicsJNI::SetPixels(env, jColors, offset, stride,
                0, 0, width, height, bitmap);
    }

    return GraphicsJNI::createBitmap(env, nativeBitmap,
            getPremulBitmapCreateFlags(isMutable));
}          getPremulBitmapCreateFlags(isMutable));

```
如果GraphicsJNI::allocateJavaPixelRef返回的Native 层的Bitmap对象为NULL，函数返回。否则，函数继续执行。
如果jColors不为NULL，那么将jColors中表示的像素值传递给前面创建在Java层的数组中。
调用GraphicsJNI::createBitmap来创建Java层的Bitmap对象。函数定义在framework/base/jni/android/graphics/Graphics.cpp中
```
jobject GraphicsJNI::createBitmap(JNIEnv* env, android::Bitmap* bitmap,
        int bitmapCreateFlags, jbyteArray ninePatchChunk, jobject ninePatchInsets,
        int density) {
    bool isMutable = bitmapCreateFlags & kBitmapCreateFlag_Mutable;
    bool isPremultiplied = bitmapCreateFlags & kBitmapCreateFlag_Premultiplied;
    // The caller needs to have already set the alpha type properly, so the
    // native SkBitmap stays in sync with the Java Bitmap.
    assert_premultiplied(bitmap->info(), isPremultiplied);

    jobject obj = env->NewObject(gBitmap_class, gBitmap_constructorMethodID,
            reinterpret_cast<jlong>(bitmap), bitmap->javaByteArray(),
            bitmap->width(), bitmap->height(), density, isMutable, isPremultiplied,
            ninePatchChunk, ninePatchInsets);
    hasException(env); // For the side effect of logging.
    return obj;
}
```
这里主要是调用jni的NewObject来创建了一个Java层的Bitmap对象，gBitmap_class代表的Java层的Bitmap类名
```
int register_android_graphics_Graphics(JNIEnv* env)
{
    ......
	gBitmap_class = make_globalref(env, "android/graphics/Bitmap");
	......
｝
```
定义在framework/base/jni/android/graphics/Graphics.cpp文件中
