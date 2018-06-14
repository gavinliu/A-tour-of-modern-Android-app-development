# LiveData

## 什么是 LiveData

LiveData 是一个具有生命周期感知能力的可被观察的数据持有类，且只有在 Lifecycle 激活状态下才会通知观察者。

## 为什么需要 LiveData

在 [如何写个高质量的 Android App？](../chapter-0/How-to-write-a-hight-quality-android-app.md) 中，提到 **避免不必要的数据更新**

1.  只有在 Lifecycle 激活状态下才会通知观察者，且如果非激活状态产生数据变更，在返回激活状态时会自动通知观察者。

    > 激活状态是指 `STARTED` `RESUMED`

2.  因为是生命周期感知的，所以在 Activity 销毁的时候，数据也会自动清除，这样就不会内存泄漏来，也不需要在 onDestory 的时候各种 `xx = null` 了。

这一切都是 LiveData 已经提供好的功能，你的使用非常简单。

## 怎么使用 LiveData

1.  直接使用 LiveData

2.  通过继承 自定义 LiveData

3.  LiveData 之间的转换

### 导入库

因为 LiveData 也属于生命周期组件的一部分，所以同样的引入 `Support Library` 26.1 以上的版本就行。

### LiveData

LiveData 是一个抽象类，其实通常是使用它其中的一个子类，MutableLiveData

```kotlin
class MainActivity : AppCompatActivity() {
    lateinit var userData: MutableLiveData<User>
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        // 1. 初始化
        userData = MutableLiveData()

        // 2. 观察，通过生命周期观察，只有在活动状态下才会接收到通知
        userData.observe(this, Observer { user ->
            // 修改 UI
            username?.text = user?.name
        })
        // 2. 观察，非生命周期观察，只要数据变化就会收到通知
        // userData.observeForever(Observer { user ->
        //     // 修改 UI
        //     username?.text = user?.name
        // })

        // 3. 修改值
        userData.value = User(0, "Liu") // 主线程修改用 setValue
        Thread(Runnable {
            Thread.sleep(2000)
            userData.postValue(User(1, "Gavin")) // 异步修改用 postValue
        }).start()
    }
}
```

LiveData 很贴心的提供了两种观察:

1.  生命周期感知的

    ```java
    public void observe(@NonNull LifecycleOwner owner, @NonNull Observer<T> observer)
    ```

    > 只有在活动状态下才会接收到通知

2.  非生命周期感知

    ```java
    public void observeForever(@NonNull Observer<T> observer)
    ```

    > 只要数据变化就会收到通知

LiveData 其实也能很好的用在异步线程中，不仅仅是 `postValue` 方法可以在异步线程中更新数据，还因为是观察者模式，能够很好的和 [Future 多线程模型](http://gavinliu.cn/2015/12/14/Java-%E4%BD%BF%E7%94%A8Future%E8%BF%9B%E8%A1%8C%E5%A4%9A%E7%BA%BF%E7%A8%8B%E7%BC%96%E7%A8%8B/) 相结合，假设需要异步获取一个 Json 数据，网络库可以直接返回一个 LiveData，等网络加载完成后，再更新数据。

### 自定义 LiveData

```kotlin
class CustomLiveData : MutableLiveData<Int>() {
    override fun onActive() {
        super.onActive()
        registerReceiver()
    }

    override fun onInactive() {
        super.onInactive()
        unregisterReceiver()
    }

    private fun registerReceiver() {

    }

    private fun unregisterReceiver() {

    }
}
```

- `onActive()` 是在 LiveData 有观察者的时候被触发，这里应该做一些初始化操作；
- `onInactive()` 是在 LiveData 没有观察者的时候被触发，这里应该做一个些数据清空的操作；

### 合并多个 LiveData

有这么个需求，一个资源可能是来源本地缓存或者网络，如何对外只暴露一个对象，就能同时收到本地缓存或者网络的数据？

通过 `MediatorLiveData`

```kotlin
// 伪代码
val networkUser = MutableLiveData<User>() // 网络
val localCacheUser = MutableLiveData<User>() // 本地缓存

val fullUserData = MediatorLiveData<User>()
fullUserData.addSource(localCacheUser, { fullUserData.value = it })
fullUserData.addSource(networkUser, { fullUserData.value = it })

fullUserData.observe(this, Observer {
    username2?.text = it?.name
})

// 异步获取
Thread(Runnable {
    localCacheUser.postValue(User(2, "User Local")) // 本地缓存先拿到
    Thread.sleep(2000)
    networkUser.postValue(User(2, "User NetWork")) // 网络数据拿到
}).start()
```

### 转换 LiveData

有时候可能需要把一个 LiveData 转换成另外一个 LiveData，那么就需要用到 LiveData 的转换功能

#### Transformations.map()

针对直接返回某个数据，用这个

```kotlin
// MainActivity.kt

teamNameData = Transformations.map(userData) { "${it.name} - Team" }
teamNameData.observe(this, Observer {
    team?.text = it
})
```

#### Transformations.switchMap()

针对返回另外一个 LiveData ，用这个

```kotlin
// MainActivity.kt

teamNameData = Transformations.map(userData) { "${it.name} - Team" }
teamNameData.observe(this, Observer {
    MutableLiveData<String>()
})
```

Transformations API，是可以实现，源数据变化后跟着变化，比如上面的例子，如果 `userData` 变了，会自动触发 `teamNameData` 变化。

## LiveData 实现原理

### 类图

{% plantuml %}

abstract class LiveData {
SafeIterableMap<Observer<T>, ObserverWrapper> mObservers

void setValue(T value)
void postValue(T value)

observe(LifecycleOwner owner, Observer<T> observer)
observeForever(Observer<T> observer)
removeObserver(Observer<T> observer)
removeObservers(LifecycleOwner owner)

void onActive()
void onInactive()

boolean hasObservers()
boolean hasActiveObservers()

int getVersion()

void dispatchingValue(ObserverWrapper initiator)
void considerNotify(ObserverWrapper observer)
}

abstract class ObserverWrapper {
-Observer<T> mObserver
-boolean mActive
-int mLastVersion

void detachObserver()
void activeStateChanged(boolean newActive)
}

class LifecycleBoundObserver {
LifecycleOwner mOwner

void onStateChanged(LifecycleOwner source, Lifecycle.Event event)
}

class AlwaysActiveObserver {

}

class MutableLiveData

class MediatorLiveData {
SafeIterableMap<LiveData<?>, Source<?>> mSources
}

class Source<V> {
LiveData<V> mLiveData
Observer<V> mObserver

void plug()
void unplug()
}

interface Observer<T> {
+void onChanged(T t)
}

LiveData <|-- MutableLiveData
MutableLiveData <|-- MediatorLiveData

ObserverWrapper <|-- LifecycleBoundObserver
GenericLifecycleObserver <|-- LifecycleBoundObserver
ObserverWrapper <|-- AlwaysActiveObserver

LiveData +-- ObserverWrapper

Observer <|-- Source

MutableLiveData +-- Source

{% endplantuml %}

### 源码解析

#### 1. LiveData 如何实现对生命周期感知的？

在添加观察者的时候需要传入 `LifecycleOwner`，然后 `addObserver()`，所以就实现了生命周期感知。同时在 `LifecycleOwner` 被销毁的时候，会自动清除数据。

```java
public void observe(@NonNull LifecycleOwner owner, @NonNull Observer<T> observer) {
    if (owner.getLifecycle().getCurrentState() == DESTROYED) {
        // ignore
        return;
    }
    LifecycleBoundObserver wrapper = new LifecycleBoundObserver(owner, observer);
    ObserverWrapper existing = mObservers.putIfAbsent(observer, wrapper);
    if (existing != null && !existing.isAttachedTo(owner)) {
    throw new IllegalArgumentException("Cannot add the same observer"
                + " with different lifecycles");
    }
    if (existing != null) {
        return;
    }
    // 生命周期监听
    owner.getLifecycle().addObserver(wrapper);
}

// DESTROYED 时清除数据
class LifecycleBoundObserver extends ObserverWrapper implements GenericLifecycleObserver {
    ...
    @Override
    public void onStateChanged(LifecycleOwner source, Lifecycle.Event event) {
        if (mOwner.getLifecycle().getCurrentState() == DESTROYED) {
            removeObserver(mObserver);
            return;
        }
        activeStateChanged(shouldBeActive());
    }
    ...
}
```

#### 2. LiveData 如何实现数据变化通知的？

```java
// 1 修改数据， postValue 最终也是调用 setValue
protected void setValue(T value) {
    assertMainThread("setValue");
    mVersion++;
    mData = value;
    dispatchingValue(null);
}
// 2 迭代通知
private void dispatchingValue(@Nullable ObserverWrapper initiator) {
    if (mDispatchingValue) {
        mDispatchInvalidated = true;
        return;
    }
    mDispatchingValue = true;
    do {
        mDispatchInvalidated = false;
        if (initiator != null) {
            considerNotify(initiator);
            initiator = null;
        } else {
            for (Iterator<Map.Entry<Observer<T>, ObserverWrapper>> iterator =
                    mObservers.iteratorWithAdditions(); iterator.hasNext(); ) {
                considerNotify(iterator.next().getValue());
                if (mDispatchInvalidated) {
                    break;
                }
            }
        }
    } while (mDispatchInvalidated);
    mDispatchingValue = false;
}
// 3 通知
private void considerNotify(ObserverWrapper observer) {
    if (!observer.mActive) {
        return;
    }
    if (!observer.shouldBeActive()) {
        observer.activeStateChanged(false);
        return;
    }
    if (observer.mLastVersion >= mVersion) {
        return;
    }
    observer.mLastVersion = mVersion;
    observer.mObserver.onChanged((T) mData);
}
```

#### 3. Transformations API 是如何实现的？

通过 MediatorLiveData 实现

##### map

```java
public static <X, Y> LiveData<Y> map(@NonNull LiveData<X> source,
        @NonNull final Function<X, Y> func) {
    final MediatorLiveData<Y> result = new MediatorLiveData<>();
    result.addSource(source, new Observer<X>() {
        @Override
        public void onChanged(@Nullable X x) {
            result.setValue(func.apply(x));
        }
    });
    return result;
}
```

##### switchMap

```java
public static <X, Y> LiveData<Y> switchMap(@NonNull LiveData<X> trigger, @NonNull final Function<X, LiveData<Y>> func) {
    final MediatorLiveData<Y> result = new MediatorLiveData<>();
    result.addSource(trigger, new Observer<X>() {
        LiveData<Y> mSource;
        @Override
        public void onChanged(@Nullable X x) {
            LiveData<Y> newLiveData = func.apply(x);
            if (mSource == newLiveData) {
                return;
            }
            if (mSource != null) {
                result.removeSource(mSource);
            }
            mSource = newLiveData;
            if (mSource != null) {
                result.addSource(mSource, new Observer<Y>() {
                    @Override
                    public void onChanged(@Nullable Y y) {
                        result.setValue(y);
                    }
                });
            }
        }
    });
    return result;
}
```

## 总结

LiveData 是不是也很简单？

除了对基本的 LiveData 操作需要了解之外，从 Transformations API 的实现就是基于 MediatorLiveData，就能知道其强大之处，原理却非常简单，所以你应该学会 `MediatorLiveData` 的用法。
