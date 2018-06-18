# ViewModel

## 什么是 ViewModel

ViewModel 主要是用来存储 UI 中需要的数据，并且支持在配置发生变化之后依然存活。

### 生命周期

![](../images/viewmodel-lifecycle.png)

在 onCleared 可以对 ViewModel 清理

## 为什么需要 ViewModel

1.  单一设计原则

    > 为了代码简洁，好维护，在 Activity 或者 Fragment 中，不应该存在与 UI 更新无关的代码，这个时候就需要把诸如数据加载等代码挪出，ViewModel 就是 UI 和 Model 之间的桥梁。

2.  数据恢复

    > 当手机配置更改，系统重新创建 Activity 时，如果数据代码写在 Activity 中，那么相应的数据也会被销毁。为了解决这个，把数据放在 ViewModel 中就不会有这个问题了。

## 怎么使用 ViewModel

### 导入库

- Support Library 26.1+
- lifecycle:extensions
  ```
  implementation "android.arch.lifecycle:extensions:1.1.1"
  ```

### 注意

ViewModel 不能引用任何 View，Lifecycle，或者 Activity Context，不然很容易引起内存泄漏。

### 和 LiveData 一起使用

```java
public class MyViewModel extends ViewModel {
    private MutableLiveData<List<User>> users;
    public LiveData<List<User>> getUsers() {
        if (users == null) {
            users = new MutableLiveData<List<User>>();
            loadUsers();
        }
        return users;
    }

    private void loadUsers() {
        ...
        // 伪代码
        ...
        users.postValue(...)
    }
}
```

> 通过 `ViewModelProviders.of(this).get(MyViewModel.class)` 实例化 `MyViewModel`

```java
public class MyActivity extends AppCompatActivity {
    public void onCreate(Bundle savedInstanceState) {
        ...
        MyViewModel model = ViewModelProviders.of(this).get(MyViewModel.class);
        model.getUsers().observe(this, users -> {
            // 更新 UI
        });
    }
}
```

### ViewModelFactory

> 如果你的 ViewModel 需要在初始化的时候传入一些参数应该怎么办呢？

> ViewModelFactory 可以帮到你

```kotlin
class ViewModelFactory(private val repository: MovieRepository) : ViewModelProvider.Factory {

    override fun <T : ViewModel?> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(MainViewModel::class.java)) {
            return MainViewModel(repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}


class MainViewModel(repository: MovieRepository) : ViewModel() {

}
```

```kotlin
ViewModelProviders.of(this, ViewModelFactory(repository)).get(MainViewModel::class.java)
```

### 在两个 Fragment 之间共享数据

> 如果两个 Fragment 都属于同一个 Activity 的话，可以通过 `ViewModelProviders.of(getActivity()).get()` 共享同一个 ViewModel

```java
public class SharedViewModel extends ViewModel {
    private final MutableLiveData<Item> selected = new MutableLiveData<Item>();

    public void select(Item item) {
        selected.setValue(item);
    }

    public LiveData<Item> getSelected() {
        return selected;
    }
}

public class MasterFragment extends Fragment {
    private SharedViewModel model;
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        model = ViewModelProviders.of(getActivity()).get(SharedViewModel.class);
        itemSelector.setOnClickListener(item -> {
            model.select(item);
        });
    }
}

public class DetailFragment extends Fragment {
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SharedViewModel model = ViewModelProviders.of(getActivity()).get(SharedViewModel.class);
        model.getSelected().observe(this, item -> {
           // Update the UI.
        });
    }
}
```

## ViewModel 实现原理

### 类图

{% plantuml %}

abstract class ViewModel {
~void onCleared()
}

class AndroidViewModel {
-Application mApplication
constructor(Application application)
}

+class ViewModelProvider {
-Factory mFactory
-ViewModelStore mViewModelStore

<T extends ViewModel> T get(Class<T> modelClass)
}

interface Factory {
<T extends ViewModel> T create(Class<T> modelClass)  
}

class NewInstanceFactory {

}

class AndroidViewModelFactory {

}

+class Fragment {
ViewModelStore mViewModelStore
}

+class FragmentActivity {
ViewModelStore mViewModelStore
}

+class ViewModelStore {
-HashMap<String, ViewModel> mMap
}

+interface ViewModelStoreOwner {
ViewModelStore getViewModelStore()
}

ViewModelProvider +-- Factory
ViewModelProvider +-- ViewModelStore
ViewModelStore +-- ViewModel
Factory <|-- NewInstanceFactory
NewInstanceFactory <|-- AndroidViewModelFactory
ViewModel <|-- AndroidViewModel
ViewModelStoreOwner <|-- Fragment
Fragment <|-- HolderFragment
ViewModelStoreOwner <|-- FragmentActivity
Fragment +-- ViewModelStore
FragmentActivity +-- ViewModelStore

class ViewModelStores {
ViewModelStore of(...)
}

class ViewModelProviders {
ViewModelProvider of(...)
}

class NonConfigurationInstances {
ViewModelStore viewModelStore
}

ViewModelStores -- ViewModelStore

ViewModelProviders -- ViewModelProvider

{% endplantuml %}

### 源码解析

#### 基本概念

- ViewModelProvider

  > 是一个用来实例化 ViewModel 的类

- ViewModelStore

  > 是一个用来存 ViewModel 的类

- ViewModelStoreOwner

  > 是一个接口，表示拥有 ViewModel 的类，对外暴露 getViewModelStore() 方法，Fragment 和 FragmentActivity 都实现了这个接口

#### 是如何实现 两个 Fragment 之间共享数据 的？

因为 FragmentActivity 和 Fragment 都实现了 ViewModelStoreOwner，就表示他们都有 ViewModelStore，都可以用来存放 ViewModel。

当使用 ViewModelProviders.of(getActivity()) 时，用同一个 activity 获得的 ViewModelProvider，实际上就是用同一个 ViewModelStore，这样 get() 到的 ViewModel 也是同一个对象。

```java
ViewModelProviders.of(getActivity()).get(SharedViewModel.class);


public class ViewModelProviders {
    ...
    public static ViewModelProvider of(@NonNull FragmentActivity activity,
            @Nullable Factory factory) {
        Application application = checkApplication(activity);
        if (factory == null) {
            factory = ViewModelProvider.AndroidViewModelFactory.getInstance(application);
        }
        // 生成 ViewModelProvider 对象
        return new ViewModelProvider(ViewModelStores.of(activity), factory);
    }
    ...
}

public class ViewModelStores {
    ...
    @NonNull
    @MainThread
    public static ViewModelStore of(@NonNull FragmentActivity activity) {
        // 如果是 ViewModelStoreOwner 就用 ViewModelStoreOwner.getViewModelStore()
        if (activity instanceof ViewModelStoreOwner) {
            return ((ViewModelStoreOwner) activity).getViewModelStore();
        }
        // 如果不是就用 HolderFragment 实现
        return holderFragmentFor(activity).getViewModelStore();
    }
    ...
}

public class ViewModelProvider {
    public <T extends ViewModel> T get(@NonNull Class<T> modelClass) {
        String canonicalName = modelClass.getCanonicalName();
        if (canonicalName == null) {
            throw new IllegalArgumentException("Local and anonymous classes can not be ViewModels");
        }
        return get(DEFAULT_KEY + ":" + canonicalName, modelClass);
    }
    public <T extends ViewModel> T get(@NonNull String key, @NonNull Class<T> modelClass) {
        ViewModel viewModel = mViewModelStore.get(key);
        // 单例，对象如果有了就直接返回
        if (modelClass.isInstance(viewModel)) {
            return (T) viewModel;
        } else {
            if (viewModel != null) {
                // TODO: log a warning.
            }
        }
        viewModel = mFactory.create(modelClass);
        mViewModelStore.put(key, viewModel);
        return (T) viewModel;
    }

    public static class NewInstanceFactory implements Factory {
        @Override
        public <T extends ViewModel> T create(@NonNull Class<T> modelClass) {
            try {
                // 实例化
                return modelClass.newInstance();
            } catch (InstantiationException e) {
                throw new RuntimeException("Cannot create an instance of " + modelClass, e);
            } catch (IllegalAccessException e) {
                throw new RuntimeException("Cannot create an instance of " + modelClass, e);
            }
        }
    }
}
```

#### 疑问？

实际上 ViewModel 是存在 ViewModelStore 中，ViewModelStore 又是放在 Activity 中，那么为啥当配置发生改变(旋转屏幕)后，Activity 重建，并不会让 ViewModel 的对象丢失，这是为啥呢？

那是因为当配置发生改变会触发 Activity#onRetainNonConfigurationInstance，然后缓存起来啦。

```java
public final Object onRetainNonConfigurationInstance() {
    ...
    // 缓存起来了
    nci.viewModelStore = mViewModelStore;
    ...
    return nci;
}

protected void onCreate(@Nullable Bundle savedInstanceState) {
    ...
    // 如果有缓存，用缓存的 ViewModelStore
    NonConfigurationInstances nc =
            (NonConfigurationInstances) getLastNonConfigurationInstance();
    if (nc != null) {
        mViewModelStore = nc.viewModelStore;
    }
    ...
}
```

## 总结

至此关于 生命周期组件 三个组件都已经讲完了，内部原理，内部代码实现都是非常简单的。在实现的 ViewModel 的时候需要注意，不要和 View 等和 Activity 的 Context 有关的类有依赖，因为 ViewModel 生命周期比 Activity 生命周期长，如果持有引用会导致内存泄漏。
