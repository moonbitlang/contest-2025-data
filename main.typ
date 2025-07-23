#import "@preview/dvdtyp:1.0.1": dvdtyp
#import "@preview/cjk-unbreak:0.1.1": remove-cjk-break-space
#show: remove-cjk-break-space

#show: dvdtyp.with(
  title: "MiniMoonBit 2025 程序设计语言规范、文法及说明",
  author: "MiniMoonBit Authors",
)
#set par(first-line-indent: 0em)

#set text(font: ("New Computer Modern", "Noto Serif CJK SC"), cjk-latin-spacing: auto)
#show raw: body => text(body, font: "Cascadia Code")
#show link: body => underline(body, offset: 0.3em)

#outline(title: "目录")

== 更新日志

- 2025-07-18 -- 初稿

= 语法定义

我们提供两种 MiniMoonBit 的语法定义，
分别为只包含必选功能的语法定义 `MiniMoonBitBasic` 和
包含所有可选功能的语法定义 `MiniMoonBit`。

我们的语法定义以 ANTLR 语法编写。
你也可以在 #link("https://github.com/moonbitlang/contest-2025-data", "我们的仓库里")
找到同样的内容。

== `MiniMoonBitBasic` 必选功能语法

#par(first-line-indent: 0em)[
  #raw(read("MiniMoonBitBasic.g4"), syntaxes: "antlr-grammar.yml", lang: "antlr")
]

== `MiniMoonBit` 含可选功能语法

#par(first-line-indent: 0em)[
  #raw(read("MiniMoonBit.g4"), syntaxes: "antlr-grammar.yml", lang: "antlr")
]

== 注意事项

1-tuple 不合法，`(expr)` 是括号表达式。

= 预定义的函数

*你的程序的主函数应当声明为 `minimbt_main`，遵循标准 C 调用约定，不接收任何参数，也不返回任何内容。你应当在汇编中将其声明为全局符号（`.global minimbt_main`）。*

运行环境中需要预先定义以下辅助函数：

```rust
// 输入输出函数
/// 读取一个整数，如果失败返回 INT_MIN
fn read_int() -> Int;
/// 打印一个整数，不带换行
fn print_int(i: Int) -> Unit;
/// 读取一个字节，如果失败返回 -1
fn read_char() -> Int;
/// 打印一个字节
fn print_char(c: Int) -> Unit;
/// 打印一个换行
fn print_endline() -> Unit;

// 数学函数
/// 整数和浮点数的互相转换
fn int_of_float(f: Double) -> Int;
fn float_of_int(i: Int) -> Double;
fn truncate(f: Double) -> Int;  // 与 int_of_float 相同
/// 浮点数运算
fn floor(f: Double) -> Double;
fn abs_float(f: Double) -> Double;
fn sqrt(f: Double) -> Double;
fn sin(f: Double) -> Double;
fn cos(f: Double) -> Double;
fn atan(f: Double) -> Double;
```

我们会以标准 RISC-V C 调用约定在提供这些函数的实现，实现的名称为实际函数名称前加入 `minimbt_`，如 `minimbt_print_int`。
在实现时，你可以认为所有不在作用域中的函数名称都是外部函数，并在函数名前加入 `minimbt_` 转换为外部调用。

此外，为了实现闭包、数组、元组等特性，我们还提供了以下内存分配函数：

```c
/// 内存分配函数
void* minimbt_malloc(int32_t size);
/// 分配对应大小的内存，并初始化所有元素为给定的值
int32_t* minimbt_create_array(int32_t n_elements, int32_t init);
double* minimbt_create_float_array(int32_t n_elements, double init);
void** minimbt_create_ptr_array(int32_t n_elements, void* init);
```

你将不需要释放内存。

= 语义

== 语义

MiniMoonBit 遵循 MoonBit 的语义规则。由于编写完整的形式语义规则不一定便于各位选手理解，我们并未计划在此处提供完整的形式语义规则。

在语义中值得注意的点如下：

=== Expression

- MiniMoonBit 中没有隐式类型转换，算术表达式的两侧表达式的类型必须相同。

- MiniMoonBit 中没有可变变量。只有数组元素可以被修改。

- `Array::make(n, k)` (`array_make_expr`) 会创建一个长度为 `n` 的数组，数组每个元素的值都是 `k`。你可以用上文提到的 `minimbt_create_{,float_,ptr_}array` 函数来实现。

- `if` 语句的多个条件分支都需要返回相同的类型。如果没有 else 分支，其类型恒定为 `Unit`。

=== Statement

- 函数需要先声明、再使用。声明的函数（除了 `main` 和 `init` 外）可以在函数体内调用自身。

- 所有定义的变量名、函数名都可以覆盖之前的定义。

  例如， ```rust let a = 1; let a = 2; a``` 中，最后的 `a` 的值是 `2`。

- 一个Block 块可以有返回值，块内的最后一条语句可以是一个expr，也可以是一个`stmt`，如果块的最后一个语句是一个`expr`，则该块的值就是这个 `expr` 的值。如果块的最后一个语句是一个 `stmt`，且这个块是一个`expr_stmt`，则该块的值就是这个 `stmt` 的值。

  例如， ```rust let a = 1; { let b = 2; a + b }``` 的值是 `3`，```rust let a = 1; { let b = 2; a + b; }``` 的值是 `3`，而```rust let a = 1; { let b = 2; let _ = a + b; }``` 的值是 `()`。



= LLVM IR

本次竞赛的评测机可以接收两种形式的提交，一种是RISCV64汇编代码，一种是LLVM IR代码。采用RISCV64汇编代码，并且测评通过的选手，将会获得额外的“寄存器分配”项目的加分。

对于期望提交LLVM IR代码的选手，请注意评测机是使用wasm来编译你的编译器项目的，因此Moonbit的官方llvm绑定`llvm.mbt` 无法在评测机上使用。但Moonbit官方为此次竞赛提供了另一个`MoonLLVM`的项目，它复刻了一个小型的llvm，可以生成满足llvm-19标准的LLVM IR代码。`MoonLLVM`所提供的API与`llvm.mbt`高度相似，多数情况下可以直接替换。你可以在比赛的前半程先使用`llvm.mbt`进行开发，确保生成标准的llvm IR代码，然后在比赛的后半程切换到`MoonLLVM`，以便提交。

请注意`llvm.mbt`和`MoonLLVM`的使用并不是强制的，你也可以在Mooncakes上寻找其它的LLVM IR生成库，或是自行实现一个llvm IR生成工具，满足llvm-19标准即可。

对于使用`MoonLLVM`，或者中间代码使用llvm IR的选手，如果最终结果仍然输出了RISCV64汇编代码，仍然可以获得“寄存器分配”项目的加分。

自8月1日起到比赛结束，`llvm.mbt` 的breaking change将会给出warning提示。自8月10日起到比赛结束，`MoonLLVM` 的breaking change将会给出warning提示。期间两个项目的一些warning提示可能会直接与竞赛相关，比赛结束之后，将会删除与竞赛相关的warning提示。

