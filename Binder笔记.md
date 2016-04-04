# Binder笔记

Android系统中IPC的实现方式采用了Binder，通过Binder Android应用层可以很容易实现跨进程调用。onServiceConnected的方法参数中service的真实类型为BinderProxy。当我们调用asInfterface后，
Proxy的mRemote就是BinderProxy.
android.os.BinderProxy位于android.os.Binder.java中，其native代码位于android_util_Binder.cpp中。
AndroidRuntime::registerNativeMethods可以讲本地方法和java的native方法建立对应关系

android_util_Binder.cpp中的ibinderForJavaObject和javaObjectForIBinder是为parcel转换binder服务的。
ibinderForJavaObject: Binder --> JavaBBinder, BinderProxy --> IBinder
javaObjectForIBinder: JavaBBinder --> Binder, IBinder --> BinderProxy

andorid.os.Binder和Native层的JavaBBinder对应，android.os.Binder.mObject保存JavaBBinderHolder的地址。
JavaBBinder的mObject引用着android.os.Binder对象。


service                    ActivityManager                     client
Binder                     BinderProxy                         BinderProxy

Parcel.cpp
```
sp<IBinder> Parcel::readStrongBinder() const
{
    sp<IBinder> val;
    unflatten_binder(ProcessState::self(), *this, &val);
    return val;
}
```
调用unflatten_binder函数从Parcel中读取binder。
```
status_t unflatten_binder(const sp<ProcessState>& proc, const Parcel& in, sp<IBinder>* out)
{
    const flat_binder_object* flat = in.readObject(false);//false表示是否读取MetaData

    if (flat) {
        switch (flat->type) {
            case BINDER_TYPE_BINDER:
                *out = reinterpret_cast<IBinder*>(flat->cookie);
                return finish_unflatten_binder(NULL, *flat, in);
            case BINDER_TYPE_HANDLE:
                *out = proc->getStrongProxyForHandle(flat->handle);
                return finish_unflatten_binder(
                    static_cast<BpBinder*>(out->get()), *flat, in);
        }
    }
    return BAD_TYPE;
}
```
通过readObject方法从Parcel中读取一个flat_binder_object的结构对象
flat_binder_object是通过flatten_binder写入到Parcel中的。
```
status_t flatten_binder(const sp<ProcessState>& /*proc*/,
    const sp<IBinder>& binder, Parcel* out)
{
    flat_binder_object obj;

    obj.flags = 0x7f | FLAT_BINDER_FLAG_ACCEPTS_FDS;
    if (binder != NULL) {
        IBinder *local = binder->localBinder();
        if (!local) {
            BpBinder *proxy = binder->remoteBinder();
            if (proxy == NULL) {
                ALOGE("null proxy");
            }
            const int32_t handle = proxy ? proxy->handle() : 0;
            obj.type = BINDER_TYPE_HANDLE;
            obj.binder = 0; /* Don't pass uninitialized stack data to a remote process */
            obj.handle = handle;
            obj.cookie = 0;
        } else {
            obj.type = BINDER_TYPE_BINDER;
            obj.binder = reinterpret_cast<uintptr_t>(local->getWeakRefs());
            obj.cookie = reinterpret_cast<uintptr_t>(local);
        }
    } else {
        obj.type = BINDER_TYPE_BINDER;
        obj.binder = 0;
        obj.cookie = 0;
    }

    return finish_flatten_binder(binder, obj, out);
}
```
这个函数位于frameworks/native/libs/native/Parcel.cpp
这个方法会将binder写到parcel中去。
localBinder是IBinder的方法。
```
//IBinder默认返回NULL
BBinder* IBinder::localBinder()
{
    return NULL;
}
//BBinder继承IBinder，重载localBinder，返回this。
BBinder* BBinder::localBinder()
{
    return this;
}

BpBinder* BpBinder::remoteBinder()
{
    return this;
}
```
BpBinder也继承自BpBinder，BpBinder没有重载localBinder。由此可见，BBinder在写入Parcel的时候，type为BINDER_TYPE_BINDER，BpBinder在写入Parcel的时候，type为BINDER_TYPE_HANDLE。
Binder驱动会将type为BINDER_TYPE_HANDLE，BINDER_TYPE_WEAK_HANDLE的flat_binder_object的type置为BINDER_TYPE_BINDER，将type为BINDER_TYPE_BINDER，BINDER_TYPE_WEAK_BINDER的flat_binder_object的type置为BINDER_TYPE_HANDLE。
>无论是Binder实体还是对实体的引用都从属与某个进程，所以该结构不能透明地在进程之间传输，必须有驱动的参与。例如当Server把 Binder实体传递给Client时，在发送数据中，flat_binder_object中的type是 BINDER_TYPE_BINDER，binder指向Server进程用户空间地址。如果透传给接收端将毫无用处，驱动必须对数据流中的这个 Binder做修改：将type该成BINDER_TYPE_HANDLE；为这个Binder在接收进程中创建位于内核中的引用并将引用号填入 handle中。对于发生数据流中引用类型的Binder也要做同样转换。经过处理后接收进程从数据流中取得的Binder引用才是有效的，才可以将其填入数据包binder_transaction_data的target.handle域，向Binder实体发送请求。

>这样做也是出于安全性考虑：应用程序不能随便猜测一个引用号填入target.handle中就可以向Server请求服务了，因为驱动并没有为你在内核中创建该引用，必定会驱动被拒绝。唯有经过身份认证确认合法后，由‘权威机构’通过数据流授予你的Binder才能使用，因为这时驱动已经在内核中为你建立了引用，交给你的引用号是合法的。

Binder 类型（ type 域）  | 在发送方的操作  |  在接收方的操作
--|---|--
 BINDER_TYPE_BINDER BINDER_TYPE_WEAK_BINDER     |  只有实体所在的进程能发送该类型的Binder。如果是第一次发送驱动将创建实体在内核中的节点，并保存binder，cookie，flag域。 |  如果是第一次接收该Binder则创建实体在内核中的引用；将handle域替换为新建的引用号；将type域替换为 BINDER_TYPE_(WEAK_)HANDLE
 BINDER_TYPE_HANDLE BINDER_TYPE_WEAK_HANDLE |  获得Binder引用的进程都能发送该类型Binder。驱动根据handle域提供的引用号查找建立在内核的引用。如果找到说明引用号合法，否则拒绝该发送请求。 |  如果收到的Binder实体位于接收进程中：将ptr域替换为保存在节点中的binder值；cookie替换为保存在节点中的cookie 值；type替换为BINDER_TYPE_(WEAK_)BINDER。
如果收到的Binder实体不在接收进程中：如果是第一次接收则创建实体在内核中的引用；将handle域替换为新建的引用号
BINDER_TYPE_FD | 验证handle域中提供的打开文件号是否有效，无效则拒绝该发送请求。|在接收方创建新的打开文件号并将其与提供的打开文件描述结构绑定。
Binder驱动程序位于kernel/moto/shamu/drivers/staging/android/binder.c

[Android Binder设计与实现](http://www.cnblogs.com/albert1017/p/3849585.html)
