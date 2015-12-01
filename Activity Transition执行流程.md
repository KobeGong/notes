#Activity Trasition实现流程
Activity的PerformCreate函数

    final void performCreate(Bundle icicle) {
        onCreate(icicle);
        mActivityTransitionState.readState(icicle);
        performCreateCommon();
    }
    final void performCreateCommon() {
        mVisibleFromClient = !mWindow.getWindowStyle().getBoolean(
		                              com.android.internal.R.styleable.Window_windowNoDisplay, false);
        mFragments.dispatchActivityCreated();
        mActivityTransitionState.setEnterActivityOptions(this, getActivityOptions());
    }

setEnterActivityOptions(Activity activity, ActivityOptions options)方法
```
public void setEnterActivityOptions(Activity activity, ActivityOptions options) {
        if (activity.getWindow().hasFeature(Window.FEATURE_ACTIVITY_TRANSITIONS)
                && options != null && mEnterActivityOptions == null
                && mEnterTransitionCoordinator == null
                && options.getAnimationType() == ActivityOptions.ANIM_SCENE_TRANSITION) {
            mEnterActivityOptions = options;
            mIsEnterTriggered = false;
            if (mEnterActivityOptions.isReturning()) {
                restoreExitedViews();
                int result = mEnterActivityOptions.getResultCode();
                if (result != 0) {
                    activity.onActivityReenter(result, mEnterActivityOptions.getResultData());
                }
            }
        }
    }
```
framework/base/core/java/android/app/ActivityTransitionState.java

Activity.performStart()
```
final void performStart() {
        mActivityTransitionState.setEnterActivityOptions(this, getActivityOptions());
        mFragments.noteStateNotSaved();
        mCalled = false;
        mFragments.execPendingActions();
        mInstrumentation.callActivityOnStart(this);
        if (!mCalled) {
            throw new SuperNotCalledException(
                "Activity " + mComponent.toShortString() +
                " did not call through to super.onStart()");
        }
        mFragments.dispatchStart();
        mFragments.reportLoaderStart();
        mActivityTransitionState.enterReady(this);
    }
```
framework/base/core/java/android/app/Activity.java

进入ActivityTransitionState.enterReady(Activity activity)
```
public void enterReady(Activity activity) {
        if (mEnterActivityOptions == null || mIsEnterTriggered) {
            return;
        }
        mIsEnterTriggered = true;
        mHasExited = false;
        ArrayList<String> sharedElementNames = mEnterActivityOptions.getSharedElementNames();
        ResultReceiver resultReceiver = mEnterActivityOptions.getResultReceiver();
        if (mEnterActivityOptions.isReturning()) {
            restoreExitedViews();
            activity.getWindow().getDecorView().setVisibility(View.VISIBLE);
        }
        mEnterTransitionCoordinator = new EnterTransitionCoordinator(activity,
                resultReceiver, sharedElementNames, mEnterActivityOptions.isReturning());

        if (!mIsEnterPostponed) {
            startEnter();
        }
    }
```
如果动画没有postponed,执行startEnter()方法

```
private void startEnter() {
        if (mEnterActivityOptions.isReturning()) {
            if (mExitingToView != null) {
                mEnterTransitionCoordinator.viewInstancesReady(mExitingFrom, mExitingTo,
                        mExitingToView);
            } else {
                mEnterTransitionCoordinator.namedViewsReady(mExitingFrom, mExitingTo);
            }
        } else {
            mEnterTransitionCoordinator.namedViewsReady(null, null);
            mEnteringNames = mEnterTransitionCoordinator.getAllSharedElementNames();
        }

        mExitingFrom = null;
        mExitingTo = null;
        mExitingToView = null;
        mEnterActivityOptions = null;
    }
```
新启动的Activity, mEnterActivityOptions.isReturning()为false ,进入else。
```
public void namedViewsReady(ArrayList<String> accepted, ArrayList<String> localNames) {
        triggerViewsReady(mapNamedElements(accepted, localNames));
    }
private void triggerViewsReady(final ArrayMap<String, View> sharedElements) {
        if (mAreViewsReady) {
            return;
        }
        mAreViewsReady = true;
        final ViewGroup decor = getDecor();
        // Ensure the views have been laid out before capturing the views -- we need the epicenter.
        if (decor == null || (decor.isAttachedToWindow() &&
                (sharedElements.isEmpty() || !sharedElements.valueAt(0).isLayoutRequested()))) {
            viewsReady(sharedElements);
        } else {
            decor.getViewTreeObserver()
                    .addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
                        @Override
                        public boolean onPreDraw() {
                            decor.getViewTreeObserver().removeOnPreDrawListener(this);
                            viewsReady(sharedElements);
                            return true;
                        }
                    });
        }
    }

```

```
protected void viewsReady(ArrayMap<String, View> sharedElements) {
        super.viewsReady(sharedElements);
        mIsReadyForTransition = true;
        hideViews(mSharedElements);
        if (getViewsTransition() != null && mTransitioningViews != null) {
            hideViews(mTransitioningViews);
        }
        if (mIsReturning) {
            sendSharedElementDestination();
        } else {
            moveSharedElementsToOverlay();
        }
        if (mSharedElementsBundle != null) {
            onTakeSharedElements();
        }
    }
```
上面这段代码主要有三个步骤：
1. hideView. 将mSharedElements中的view的alpha值设为0.
```
protected void hideViews(ArrayList<View> views) {
        int count = views.size();
        for (int i = 0; i < count; i++) {
            View view = views.get(i);
            if (!mOriginalAlphas.containsKey(view)) {
                mOriginalAlphas.put(view, view.getAlpha());
            }
            view.setAlpha(0f);
        }
    }
```
2. moveSharedElementsToOverlay. 将mSharedElements的view添加到ViewOverlay。
```
protected void moveSharedElementsToOverlay() {
        if (mWindow == null || !mWindow.getSharedElementsUseOverlay()) {
            return;
        }
        setSharedElementMatrices();
        int numSharedElements = mSharedElements.size();
        ViewGroup decor = getDecor();
        if (decor != null) {
            boolean moveWithParent = moveSharedElementWithParent();
            Matrix tempMatrix = new Matrix();
            for (int i = 0; i < numSharedElements; i++) {
                View view = mSharedElements.get(i);
                tempMatrix.reset();
                mSharedElementParentMatrices.get(i).invert(tempMatrix);
                GhostView.addGhost(view, decor, tempMatrix);
                ViewGroup parent = (ViewGroup) view.getParent();
                if (moveWithParent && !isInTransitionGroup(parent, decor)) {
                    GhostViewListeners listener = new GhostViewListeners(view, parent, decor);
                    parent.getViewTreeObserver().addOnPreDrawListener(listener);
                    mGhostViewListeners.add(listener);
                }
            }
        }
    }
```
3. onTakeSharedElements. 开始Transition动画。
```
private void onTakeSharedElements() {
        if (!mIsReadyForTransition || mSharedElementsBundle == null) {
            return;
        }
        final Bundle sharedElementState = mSharedElementsBundle;
        mSharedElementsBundle = null;
        OnSharedElementsReadyListener listener = new OnSharedElementsReadyListener() {
            @Override
            public void onSharedElementsReady() {
                final View decorView = getDecor();
                if (decorView != null) {
                    decorView.getViewTreeObserver()
                            .addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
                                @Override
                                public boolean onPreDraw() {
                                    decorView.getViewTreeObserver().removeOnPreDrawListener(this);
                                    startTransition(new Runnable() {
                                        @Override
                                        public void run() {
                                            startSharedElementTransition(sharedElementState);
                                        }
                                    });
                                    return false;
                                }
                            });
                    decorView.invalidate();
                }
            }
        };
        if (mListener == null) {
            listener.onSharedElementsReady();
        } else {
            mListener.onSharedElementsArrived(mSharedElementNames, mSharedElements, listener);
        }
    }
```
开始执行动画
```
private void startSharedElementTransition(Bundle sharedElementState) {
        ViewGroup decorView = getDecor();
        if (decorView == null) {
            return;
        }
        // Remove rejected shared elements
        ArrayList<String> rejectedNames = new ArrayList<String>(mAllSharedElementNames);
        rejectedNames.removeAll(mSharedElementNames);
        ArrayList<View> rejectedSnapshots = createSnapshots(sharedElementState, rejectedNames);
        if (mListener != null) {
            mListener.onRejectSharedElements(rejectedSnapshots);
        }
        removeNullViews(rejectedSnapshots);
        startRejectedAnimations(rejectedSnapshots);

        // Now start shared element transition
        ArrayList<View> sharedElementSnapshots = createSnapshots(sharedElementState,
                mSharedElementNames);
        showViews(mSharedElements, true);
        scheduleSetSharedElementEnd(sharedElementSnapshots);
        ArrayList<SharedElementOriginalState> originalImageViewState =
                setSharedElementState(sharedElementState, sharedElementSnapshots);
        requestLayoutForSharedElements();

        boolean startEnterTransition = allowOverlappingTransitions() && !mIsReturning;
        boolean startSharedElementTransition = true;
        setGhostVisibility(View.INVISIBLE);
        scheduleGhostVisibilityChange(View.INVISIBLE);
        pauseInput();
        Transition transition = beginTransition(decorView, startEnterTransition,
                startSharedElementTransition);
        scheduleGhostVisibilityChange(View.VISIBLE);
        setGhostVisibility(View.VISIBLE);

        if (startEnterTransition) {
            startEnterTransition(transition);
        }

        setOriginalSharedElementState(mSharedElements, originalImageViewState);

        if (mResultReceiver != null) {
            // We can't trust that the view will disappear on the same frame that the shared
            // element appears here. Assure that we get at least 2 frames for double-buffering.
            decorView.postOnAnimation(new Runnable() {
                int mAnimations;

                @Override
                public void run() {
                    if (mAnimations++ < MIN_ANIMATION_FRAMES) {
                        View decorView = getDecor();
                        if (decorView != null) {
                            decorView.postOnAnimation(this);
                        }
                    } else if (mResultReceiver != null) {
                        mResultReceiver.send(MSG_HIDE_SHARED_ELEMENTS, null);
                        mResultReceiver = null; // all done sending messages.
                    }
                }
            });
        }
    }

```
