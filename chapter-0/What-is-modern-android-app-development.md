#什么是现代 Android App 开发？

Android 开发真的是个很广泛的范围，包括不限于：`内核`，`驱动`，`相机 HAL`、`多媒体`、`通讯` 等，这里我们只讨论 App 开发。

Android 从 2008 发布到现在已经 10 个年头了，现在的开发方式和起初有了很大的变化，原因有两点：

1.  Android 官方不断更新了更好用的组件

    > 比如 RecyclerView，Appcompat，ConstraintLayout 等

2.  日渐繁荣的开源社区生态

    > 比如 OkHttp 系列，Rxjava，EventBus 等

## 一、时间线

Android App 开发比较重要的时间节点

- `2008` Android 1.0 发布，应用程序使用 eclipse 开发
- `2013` Android Studio 发布，五年时间过去了，终于有了属于 Android 自己的开发环境
- `2013` Appcompat Library 发布，实现了 Toolbar 的适配，至今都是每个 App 必导库
- `2014` RecyclerView 发布，其高性能易扩展的特性，几乎所有的列表页面都会用到它
- `2017` ConstraintLayout 发布，让 View 更简单的组织起来，且有更好的性能，能简单实现联动效果
- `2017` Kotlin 正式成为官方开发语言，其空安全特性，各种语法糖等，让你对 Java 啰嗦语法说拜拜
- `2017` ArchComponents 发布，这是一个官方版本的 Android 架构组件，专注解决生命周期管理问题
- `2018` KTX，通过 Kotlin 扩展系统 API，使 API 调用更简单
- `2018` Google I/O 提出 `Jetpack` 概念

---

`Jetpack` 其实不是什么新东西，是把之前发布的一些东西分门别类，取了个高大上的名称，其中架构组件是重头戏。

- 架构组件 (Architecture Components)
- 基础组件 (Foundation Components)
- 界面组件 (UI Components)
- 行为组件 (Behavior Components)

## 二、选择

### 架构模式

这部分设计原则在 [上一篇](How-to-write-a-hight-quality-android-app.md) 讲得很清楚了，具体架构模式应该根据情况选你喜欢的方式，架构没有绝对的好与坏。

参考：[android-architecture](https://github.com/googlesamples/android-architecture)

### Activitys

尽可能在每个入口使用单 Activity，然后使用 `ArchComponents: Navigation` 管理页面

### Fragments

`Fragment` 应该使用 support 包里面的，不要用 Android 包内的

### Services

在 `Oreo` 上，系统不允许隐式的后台服务，所以你至少应该学会 `JobIntentService` 的使用方法

### Layouts

- ~~`AbsoluteLayout`~~ 不建议使用
- ~~`GirdLayout`~~ 使用 `RecyclerView` 替代
- ~~`RelativeLayout`~~ 使用 `ConstraintLayout` 替代
- `LinearLayout` 可用在简单的布局中
- `FrameLayout` 需要注意 `margin`用于填充空间是可以的，但是不要是用 `margin` 来控制位置，这样就相当于是 ~~`AbsoluteLayout`~~
- `ConstraintLayout` 推荐

### AdapterViews

- ~~`ListView`~~
- ~~`GirdView`~~
- ~~`Gallery`~~

全部弃用，使用 `RecyclerView` 替代，可以做到更好的动画和颗粒度更细的更新

### 生命周期管理

使用 `ArchComponents: Lifecylce`

### 数据库

使用 `ArchComponents: Room`

### 数据分页

使用 `ArchComponents: Paging`

### 图像

`VectorDrawable` 几乎可以代替软件要用到所有的图标

### 网络

只推荐 `OkHttp` ，毕竟 Android 系统的 URLConnection 都换成了 OKHttp 的实现

### 图片缓存

`Glide`、`Picasso`、`Fresco` 三大框架，任选其一即可，个人推荐 `Glide`

### 异步线程

`Rxjava`

### 路由 & Deeplink

使用 `ArchComponents: Navigation`

## 三、 推荐
