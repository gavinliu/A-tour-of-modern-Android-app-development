# 生命周期感知组件 (Lifecycle-Aware Components)

## 什么是 Lifecycle-Aware 组件

生命周期感知组件是一套可以感知 `Activity` 和 `Fragment` 生命周期的框架，可以用很少的代码实现生命周期监听。

## 为什么需要 Lifecycle-Aware 组件

为了实现单一设计原则，把原本在 `Activity` 和 `Fragment` 中的业务代码分离出来，但是业务代码需要知道 UI 的状态，比如需要在页面退出的时候 停止网络数据连接等，所以设计了这么个组件。

有了这个组件，现在在实现 MVP 架构中，Presenter 想要知道 UI 界面的生命周期，就 **不需要** 自己声明一系列方法，在 UI 中手动回调。

## 怎么使用 Lifecycle-Aware 组件

### 基本概念

生命周期感知组件有三个概念：

1.  Lifecycle ：表示生命周期，是一个对象，是个被观察者；

    ```java
    public abstract class Lifecycle {
      @MainThread
      public abstract void addObserver(@NonNull LifecycleObserver observer);

      @MainThread
      public abstract void removeObserver(@NonNull LifecycleObserver observer);

      @MainThread
      @NonNull
      public abstract State getCurrentState();
    }
    ```

2.  LifecycleOwner ：表示生命周期拥有者，是一个接口，对外暴露 `getLifecycle()` 方法

    ```java
    public interface LifecycleOwner {
      @NonNull
      Lifecycle getLifecycle();
    }
    ```

3.  LifecycleObserver ：表示生命周期观察者，是一个接口，用来观察 Lifecycle。

    ```java
    interface FullLifecycleObserver extends LifecycleObserver {
      void onCreate(LifecycleOwner owner);

      void onStart(LifecycleOwner owner);

      void onResume(LifecycleOwner owner);

      void onPause(LifecycleOwner owner);

      void onStop(LifecycleOwner owner);

      void onDestroy(LifecycleOwner owner);
    }
    ```

那么 LifecycleOwner 其实就是 `Activity` 或者 `Fragment`，我们可以在 `Activity` 或者 `Fragment` 中使用 `getLifecycle()` 获取 Lifecycle，然后 `Lifecycle.addObserver(MyLifecycleObserver())`，即可感知到生命周期。

### 导入库

从 `Support Library 26.1` 开始依赖 `Lifecycle-Aware` 组件，所以直接使用 26.1 版本以上的 `Support Library` 即可。

不建议在 26.1 版本以下，引用 `Lifecycle-Aware` 组件，这样你需要单独对 `Activity` 或者 `Fragment` 做生命周期感知适配。

### 实现 LifecycleObserver

有两种方式:

1.  使用 `OnLifecycleEvent` 注解

    ```kotlin
    class MyLifecycleObserver : LifecycleObserver {

        @OnLifecycleEvent(Lifecycle.Event.ON_CREATE)
        fun onCreate() {
            Log.d("MyLifecycleObserver", "onCreate")
        }

        @OnLifecycleEvent(Lifecycle.Event.ON_START)
        fun onStart() {
            Log.d("MyLifecycleObserver", "onStart")
        }

        @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
        fun onResume() {
            Log.d("MyLifecycleObserver", "onResume")
        }

        @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
        fun onPause() {
            Log.d("MyLifecycleObserver", "onPause")
        }

        @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
        fun onStop() {
            Log.d("MyLifecycleObserver", "onStop")
        }

        @OnLifecycleEvent(Lifecycle.Event.ON_DESTROY)
        fun onDestroy() {
            Log.d("MyLifecycleObserver", "onDestroy")
        }
    }
    ```

2.  实现 `GenericLifecycleObserver` 接口

    ```kotlin
    class MyGenericLifecycleObserver : GenericLifecycleObserver {
        override fun onStateChanged(source: LifecycleOwner?, event: Lifecycle.Event?) {
            Log.d("onStateChanged", event?.name)
        }
    }
    ```

### 注册 LifecycleObserver

```kotlin
lifecycle.addObserver(MyLifecycleObserver())
lifecycle.addObserver(MyGenericLifecycleObserver())
```

### 运行效果

```console
D/MyLifecycleObserver: onCreate
D/onStateChanged: ON_CREATE
D/MyLifecycleObserver: onStart
D/onStateChanged: ON_START
D/MyLifecycleObserver: onResume
D/onStateChanged: ON_RESUME
D/onStateChanged: ON_PAUSE
D/MyLifecycleObserver: onPause
D/onStateChanged: ON_STOP
D/MyLifecycleObserver: onStop
D/onStateChanged: ON_DESTROY
D/MyLifecycleObserver: onDestroy
```

## Lifecycle-Aware 组件实现原理

### 类图

{% plantuml %}
abstract class Lifecycle {
+void addObserver(LifecycleObserver observer)
+void removeObserver(LifecycleObserver observer)
+State getCurrentState()
}

enum Event {
ON_CREATE
ON_START
ON_RESUME
ON_PAUSE
ON_STOP
ON_DESTROY
ON_ANY
}

enum State {
DESTROYED
INITIALIZED
CREATED
STARTED
RESUMED

boolean isAtLeast(State state)
}

interface LifecycleOwner {
+Lifecycle getLifecycle()
}

class Fragment {
-LifecycleRegistry mLifecycleRegistry

-void performCreate()
-void performStart()
-void performResume()
-void performPause()
-void performStop()
-void performDestroy()
}

class LifecycleRegistry {
-FastSafeIterableMap<LifecycleObserver, ObserverWithState> mObserverMap

+handleLifecycleEvent(Lifecycle.Event event)
}

class ObserverWithState {
-State mState
-GenericLifecycleObserver mLifecycleObserver

-void dispatchEvent(LifecycleOwner owner, Event event)
}

interface LifecycleObserver
interface GenericLifecycleObserver {
+void onStateChanged(LifecycleOwner source, Lifecycle.Event event);
}
interface FullLifecycleObserver {
+void onCreate(LifecycleOwner owner)
+void onStart(LifecycleOwner owner)
+void onResume(LifecycleOwner owner)
+void onPause(LifecycleOwner owner)
+void onStop(LifecycleOwner owner)
+void onDestroy(LifecycleOwner owner)
}

class FullLifecycleObserverAdapter {
-FullLifecycleObserver mObserver
}

LifecycleObserver <|-- FullLifecycleObserver
LifecycleObserver <|-- GenericLifecycleObserver
LifecycleOwner <|-- Fragment
Lifecycle <|-- LifecycleRegistry
LifecycleRegistry <-- Fragment
Lifecycle +-- Event
Lifecycle +-- State

LifecycleRegistry +-- ObserverWithState
ObserverWithState --> GenericLifecycleObserver
GenericLifecycleObserver <|-- FullLifecycleObserverAdapter
FullLifecycleObserverAdapter -> FullLifecycleObserver
{% endplantuml %}

### 源码解析

看源码当然不是拿到源码直接就看，对于这个组件，我们这里需要弄明白这几个问题就行了：

#### 1. Lifecycle 内部有 Event 和 State 两个类，它们是什么关系？

    Event：表示的是生命周期的事件

    State：表示的是 Lifecycle 当前的状态

    ![](../images/lifecycle-states.png)

    上图就是 State 和 Event 之间的转换，迁移图，对于的代码如下：

    ```java
    // LifecycleRegistry.java

    // 当前事件发生后的状态
    static State getStateAfter(Event event) {
        switch (event) {
            case ON_CREATE:
            case ON_STOP:
                return CREATED;
            case ON_START:
            case ON_PAUSE:
                return STARTED;
            case ON_RESUME:
                return RESUMED;
            case ON_DESTROY:
                return DESTROYED;
            case ON_ANY:
                break;
        }
        throw new IllegalArgumentException("Unexpected event value " + event);
    }
    // 状态向后移动，到达这个状态，应该是由什么事件触发
    private static Event downEvent(State state) {
        switch (state) {
            case INITIALIZED:
                throw new IllegalArgumentException();
            case CREATED:
                return ON_DESTROY;
            case STARTED:
                return ON_STOP;
            case RESUMED:
                return ON_PAUSE;
            case DESTROYED:
                throw new IllegalArgumentException();
        }
        throw new IllegalArgumentException("Unexpected state value " + state);
    }
    // 状态向前移动，到达这个状态，应该是由什么事件触发
    private static Event upEvent(State state) {
        switch (state) {
            case INITIALIZED:
            case DESTROYED:
                return ON_CREATE;
            case CREATED:
                return ON_START;
            case STARTED:
                return ON_RESUME;
            case RESUMED:
                throw new IllegalArgumentException();
        }
        throw new IllegalArgumentException("Unexpected state value " + state);
    }
    ```

#### 2. 注册 LifecycleObserver 后，LifecycleObserver 对象是怎么存储的，存了些什么东西？

    ```java
    // LifecycleRegistry.java

    private FastSafeIterableMap<LifecycleObserver, ObserverWithState> mObserverMap =
            new FastSafeIterableMap<>();
    // LifecycleObserver 是存在 FastSafeIterableMap 里的，内部是用 链表 实现的 Map 数据结构
    // 同时存放在 ObserverWithState 里面
    public void addObserver(@NonNull LifecycleObserver observer) {
        State initialState = mState == DESTROYED ? DESTROYED : INITIALIZED;
        ObserverWithState statefulObserver = new ObserverWithState(observer, initialState);
        // 如果已经有了就返回 map 里面的那个
        ObserverWithState previous = mObserverMap.putIfAbsent(observer, statefulObserver);

        // 如果已经 add 了就直接返回
        if (previous != null) {
            return;
        }

        // 如果 LifecycleOwner 被GC回收 就返回
        LifecycleOwner lifecycleOwner = mLifecycleOwner.get();
        if (lifecycleOwner == null) {
            // it is null we should be destroyed. Fallback quickly
            return;
        }

        // 下面这一段是为了解决，假如你是在 onResume 的时候才 add 的 LifecycleObserver
        // 同样会收到 onResume 之前的事件
        boolean isReentrance = mAddingObserverCounter != 0 || mHandlingEvent;
        State targetState = calculateTargetState(observer);
        mAddingObserverCounter++;
        while ((statefulObserver.mState.compareTo(targetState) < 0
                && mObserverMap.contains(observer))) {
            pushParentState(statefulObserver.mState);
            statefulObserver.dispatchEvent(lifecycleOwner, upEvent(statefulObserver.mState));
            popParentState();
            // mState / subling may have been changed recalculate
            targetState = calculateTargetState(observer);
        }

        // 同步分发
        if (!isReentrance) {
            // we do sync only on the top level.
            sync();
        }
        mAddingObserverCounter--;
    }
    ```

#### 3. 生命周期是如何通知到 LifecycleObserver？

    ```java
    // Fragment.java

    LifecycleRegistry mLifecycleRegistry = new LifecycleRegistry(this);

    void performCreate(Bundle savedInstanceState) {
        if (mChildFragmentManager != null) {
            mChildFragmentManager.noteStateNotSaved();
        }
        mState = CREATED;
        mCalled = false;
        onCreate(savedInstanceState);
        mIsCreated = true;
        if (!mCalled) {
            throw new SuperNotCalledException("Fragment " + this
                    + " did not call through to super.onCreate()");
        }
        // 1 分发 ON_CREATE 事件
        mLifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE);
    }
    ```

    ```java
    // LifecycleRegistry.java

    public void handleLifecycleEvent(@NonNull Lifecycle.Event event) {
        State next = getStateAfter(event); // 当前事件发生后的状态
        moveToState(next);
    }

    // 2 设置状态
    private void moveToState(State next) {
        if (mState == next) {
            return;
        }
        mState = next;
        if (mHandlingEvent || mAddingObserverCounter != 0) {
            mNewEventOccurred = true;
            // we will figure out what to do on upper level.
            return;
        }
        mHandlingEvent = true;
        sync();
        mHandlingEvent = false;
    }
    // 3 同步状态
    private void sync() {
        LifecycleOwner lifecycleOwner = mLifecycleOwner.get();
        if (lifecycleOwner == null) {
            Log.w(LOG_TAG, "LifecycleOwner is garbage collected, you shouldn't try dispatch "
                    + "new events from it.");
            return;
        }
        while (!isSynced()) {
            mNewEventOccurred = false;
            // 如果 当前状态 比之前的状态低，那么状态就向后传递
            // 也就是 DESTROYED <- INITIALIZED <- CREATED <- STARTED <- RESUMED
            // 这样的状态走向，不就是程序后台了或者退出的时候嘛
            if (mState.compareTo(mObserverMap.eldest().getValue().mState) < 0) {
                backwardPass(lifecycleOwner);
            }
            Entry<LifecycleObserver, ObserverWithState> newest = mObserverMap.newest();
            if (!mNewEventOccurred && newest != null
                    && mState.compareTo(newest.getValue().mState) > 0) {
                forwardPass(lifecycleOwner);
            }
        }
        mNewEventOccurred = false;
    }
    // 4 状态向后传递
    private void backwardPass(LifecycleOwner lifecycleOwner) {
        Iterator<Entry<LifecycleObserver, ObserverWithState>> descendingIterator =
                mObserverMap.descendingIterator();
        while (descendingIterator.hasNext() && !mNewEventOccurred) {
            Entry<LifecycleObserver, ObserverWithState> entry = descendingIterator.next();
            ObserverWithState observer = entry.getValue();
            while ((observer.mState.compareTo(mState) > 0 && !mNewEventOccurred
                    && mObserverMap.contains(entry.getKey()))) {
                // 到达这个状态，应该是由什么事件触发？
                Event event = downEvent(observer.mState);
                pushParentState(getStateAfter(event));
                // 5 那么就分发这个事件
                observer.dispatchEvent(lifecycleOwner, event);
                popParentState();
            }
        }
    }

    // ... forwardPass 就不分析了，同理 ...
    ```

## 总结

Lifecycle-Aware 的实现原理非常的简单。不过通常我们不会直接使用生命周期感知组件，它存在的意义在于为 `LiveData` 和 `ViewModel` 的实现提供了基础支持。
