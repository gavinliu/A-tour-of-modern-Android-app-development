# 生命周期感知组件 (Lifecycle-Aware Components)

## 什么是 Lifecycle-Aware 组件

生命周期感知组件是一套可以感知 `Activity` 和 `Fragment` 生命周期的框架，可以用很少的代码实现生命周期监听。

## 为什么需要 Lifecycle-Aware 组件

为了实现单一设计原则，把原本在 `Activity` 和 `Fragment` 中的业务代码分离出来，但是业务代码需要知道 UI 的状态，比如需要在页面退出的时候 停止网络数据连接等，所以设计了这么个组件。

有了这个组件，现在在实现 MVP 架构中，Presenter 想要知道 UI 界面的生命周期，就 **不需要** 自己声明一系列方法，在 UI 中手动回调。

## 如何使用 Lifecycle-Aware 组件

生命周期感知组件有三个概念：

1.  Lifecycle ：是一个对象，表示 Android 中的生命周期
2.  LifecycleOwner ：是 Lifecycle 对外的一个接口，其 `getLifecycle()` 方法可以用来获取 Lifecycle
3.  LifecycleObserver ：是一个接口，用来观察 Lifecycle

那么 Lifecycle 其实就是 `Activity` 或者 `Fragment`，我们可以在 `Activity` 或者 `Fragment` 中使用 `getLifecycle()` 获取 Lifecycle，然后 `Lifecycle.addObserver(MyLifecycleObserver())`，即可感知到生命周期。

### 导入库

从 `Support Library 26.1` 开始依赖 `Lifecycle-Aware` 组件，所以直接使用 26.1+ 版本以上的 `Support Library` 即可。

不建议单独引 `Lifecycle-Aware`，这样你需要单独对 `Activity` 或者 `Fragment` 做生命周期感知适配

### 实现 LifecycleObserver

```kotlin
xx
```

### 注册 LifecycleObserver

```kotlin
xx
```

### 运行效果

```console
xx
```

## Lifecycle-Aware 组件实现原理

### 类图

### 源码解析

看源码当然不是拿到源码直接就看，对于这个组件，我们这里需要弄明白这几个问题就行了：

1.  注册 LifecycleObserver 后，LifecycleObserver 对象是怎么存储的，存了些什么东西？

2.  生命周期是如何通知到 LifecycleObserver ？

## 总结

Lifecycle-Aware 的实现原理非常的简单。不过通常我们不会直接使用生命周期感知组件，它存在的意义在于为 `LiveData` 和 `ViewModel` 的实现提供了基础支持。
