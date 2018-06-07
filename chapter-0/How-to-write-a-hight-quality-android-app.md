# 如何写个高质量的 Android App？

首先定义什么是高质量，我认为高质量至少有这几个标准：

1.  健壮性

    > 逻辑不要有漏洞，程序不要崩溃，内存不能泄漏等。

2.  易维护

    > 采用单一设计原则，每个模块只处理一件事情，易于维护。

3.  可测试

    > 每个模块都可以单独测试，不受依赖或者低耦合。

## 在 Android 平台开发遇到的挑战

与传统的桌面应用程序不同，在大多数情况下，桌面应用程序从启动程序的快捷方式中有一个入口点，并且作为单个单一进程运行。

Android App 的结构更为复杂，一个基本的 Android App 由多个 `App Component` 构成，包括 `Activity` `Fragment` `Service` `Content Provider` 和 `Broadcast Receiver` 等。

这些组件通常通过 `App manifest` 文件进行申明，让系统其他 App 或者组件能够相互集成，所以正确编写的 Android App 需要更灵活，因为用户可以通过设备上的不同应用程序进行编程，并不断切换流程和任务。

例如，在社交应用中分享照片时会发生什么？

1.  社交应用会触发相机 `Intent`；
2.  系统将启动相机应用来处理请求，用户则离开了社交应用；
3.  相机应用也可能会触发其他 `Intent`，例如启动文件选择器，该文件选择器可能会启动另一个应用；
4.  最终用户回到社交应用并分享照片；

此外，用户可能会在此过程的任何时候接听电话，并在挂断电话后返回分享照片。

在 Android 中，这种应用程序跳转行为很常见，所以您的应用程序必须正确处理这些流程。请记住，移动设备资源受限，因此操作系统在任何时候都可能需要杀死一些应用程序才能为新的进程腾出空间。

所有的这一切都意味着你的应用程序组件可以单独和无序地启动，并且可以在任何时候由用户或系统销毁。**因为 `App Component` 是短暂的，并且它们的生命周期不受你的控制，所以你不应该在 `App Component` 中存储任何应用程序数据或状态，并且与 `App Component` 不应相互依赖。**

## 如何设计应用程序

上面遇到挑战的结论是：

1.  **不应该在 `App Component` 中存储任何应用程序数据或状态**

    > 将所有代码都写入 `Activity` 和 `Fragment` 是常见错误，其实任何与 UI UX 操作无关的代码都不应该在这些类里，尽可能的保证的精简，可以避免很多生命周期的问题。

2.  **与 `App Component` 不应相互依赖**；

    > 因为内存的关系，Android 系统可能会随时销毁 `App Component`，如果业务代码依赖了的话，可能会导致 `App Component` 不能被 GC 回收，导致内存泄漏。

其次你还应该：

1.  **使用数据模型(Model)驱动 UI**

    > 这样 UI 代码只有显示，没有逻辑，会让 UI 代码变得简单，单一设计原则易于管理。

    > 数据模型是独立于 Android 的 `View` 和 `App Component` 的组件，与 Android 无关，这样也是解决相互依赖的问题。

2.  **数据模型持久化**

    > 这样可以在如果操作系统销毁了你的应用程序，或者在网络连接状况不佳或未连接时，应用程序仍可以继续工作。

## 实践方案

1.  `Model` 通过统一的 `Repository` 接口，是一个基本的抽象模式，来规范整个 App 的数据管理，实现缓存分发和持久化等功能。

2.  `ViewModel` 作为 `View` 和 `Model` 的桥梁，通常是感知生命周期的，在 View 销毁的时候，会回收 Model 数据。

![](../images/final-architecture.png)

接下来回到高质量标准：

- [x] 易维护

  > 采用 Model 驱动 UI，让 UI 代码变得简单，各司其职单一原则，目标达成。

- [x] 可测试

  > ViewModel & Model 都是简单的 Java 类，可以用 JUnit 测试，

  > UI 部分使用 Espresso。

- [x] 健壮性

  > 这部分不属于设计部分，逻辑上的健壮就需要思维缜密了。

---

Google 发布了 [Android Architecture Blueprints](https://github.com/googlesamples/android-architecture)，该项目展示了不同的架构模式的样本代码，请记住不同的架构模式没有绝对优劣之分，选择自己团队喜欢的即可。但是所有的架构模式都实践了上图的基本模型，采用 Model 来分离逻辑，UI 只做简单的显示，下面推荐几个模式：

- [todo-mvp](https://github.com/googlesamples/android-architecture/tree/todo-mvp/)

- [todo-mvvm](https://github.com/googlesamples/android-architecture/tree/todo-mvvm/)

- [todo-mvvm-live](https://github.com/googlesamples/android-architecture/tree/todo-mvvm-live/)
