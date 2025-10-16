# 处理闭包

我们到现在位置为止还差一点小问题没有处理：闭包。

[闭包][closure] (closure) 这个词在数学上有很多个含义。
在编程语言中，它指的是会使用不在函数中定义的变量的函数。

[closure]: https://en.wikipedia.org/wiki/Closure_(computer_programming)

## 为什么需要闭包

举这样一个例子吧：

```mbt
fn make_adder(x: Int) -> (Int) -> Int {
  fn adder(y: Int) {
    x + y
  }
  adder
}
```

可以看到，`adder` 的函数体中使用了 `make_adder` 中声明的变量 `x`。
这个变量并不是 `adder` 的局部变量（我们称之为自由变量 free variable），
而且在 `adder` 被调用之前，`make_adder` 就已经返回了。
因此，我们需要 `adder` 可以捕获在它使用到的局部变量的值。

> _为什么叫闭包呢？_
>
> “闭包” (closure) 这个词在数学中的含义是一个集合通过某种规则无限次扩充元素之后得到的集合。
>
> 很遗憾的，计算机中这个词的含义和数学中的一点关系都没有。
> 它的来源是说，原本对于一个函数是开放（open）的变量（也就是自由变量），
> 被关闭（close）到了一个指定的变量作用域中，
> 得到了一个“关闭的表达式”（closed expression）。
> 这个名字再之后被缩短，就变成了和数学概念重名的 closure。
>
> 这个名字在被翻译成中文的时候，借用了数学上的同名概念的翻译，因此被称作闭包。

## 实现一个闭包

一般来说，对于需要被动态传入的函数，我们会使用一个函数指针（例如 C 中的 `int (*)(int)`）去表示。
但是这个函数指针只包含了函数本身，没有包含它使用的自由变量。

如果你写过面向对象语言（比如 Java），你应该很快就能想到一个差不多能用的解决方法：
一个实现了某个接口的类和上述的函数是等价的，而被捕获的局部变量可以存到类的字段里。

```java
interface IAdder {
    int add(int y);
}

class MyAdder implements IAdder {
    int x;
    MyAdder(int x) {
        this.x = x;
    }
    int add(int y) {
        return x + y;
    }
}
```

事实上，Java 中的闭包真的就会被编译到类似结构的一个类的形式。
不过对于我们来说，这种单元素的虚表还可以进一步简化。

我们先用 C 尝试实现一个类似上述 Java 的类的数据结构。
在这里，我们直接把接口看作是对象的父类。
为了可以在不知道对象的具体类型的情况下调用它的方法，
我们把它的方法按照确定的顺序存到一个数据结构中，称为[虚表][vtable]。
为了可以访问对象内的数据，
对象的每一个方法都需要将指向对象自己的指针 `this` 传入它的第一个参数。

然后，我们把指向虚表的指针存到唯一一个不知道对象结构也可以确定的位置——对象的最开头。
我们最终得到的数据结构类似下面的这样：

[vtable]: https://en.wikipedia.org/wiki/Virtual_method_table

```c
typedef struct IAdderVTable {
    // 指向 add 函数的函数指针
    int (*add)(void*, int y);
    // 如果你不喜欢读 C 的类型定义的话：ptr(fn(ptr(void), int) -> int)
} IAdderVTable;

/// 我们可以把这个接口看作父类
typedef struct IAdder {
    IAdderVTable* vtable;
} IAdder;

typedef struct MyAdder {
    // 第一个元素是父类，父类有虚表
    IAdder super;
    // 对象的字段列表
    int x;
} MyAdder;

// 虚表
static IAdderVTable MyAdder_vtable = { MyAdder_add };

MyAdder* MyAdder_new(int x) {
    MyAdder* this = malloc(sizeof(MyAdder));
    this.super.vtable = &MyAdder_vtable;
    this.x = x;
    return adder;
}

// `add` 函数。注意它是接受 `this` 作为参数的
int MyAdder_add(MyAdder* this, int y) {
    return this.x + y;
}

// 调用
int main() {
    IAdder* adder = MyAdder_new(1);
    int result = adder.vtable.add(adder, 2);
    return 0;
}
```

既然虚表里面只有一个元素，那我们就没有必要单独用一个指针指向它了，
而可以直接把这个函数指针放到对象的字段里面。
这样，我们的定义就变成了：

```c
// IAdder 父类的定义就是一个符合闭包函数签名的函数指针
typedef IAdder int (*add)(void*, int y);

// 我们把这个指针放到对象的头部
typedef struct MyAdder {
    IAdder func_ptr;
    int x;
}
```

在调用的时候，只需要把指针从对象中取出来并调用就可以了。

```c
IAdder* adder = ...;
IAdder func_ptr = *adder;
int result = func_ptr(adder, 2);
```
