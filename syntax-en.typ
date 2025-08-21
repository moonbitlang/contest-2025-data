#import "@preview/dvdtyp:1.0.1": dvdtyp
#import "@preview/cjk-unbreak:0.1.1": remove-cjk-break-space
#show: remove-cjk-break-space

#show: dvdtyp.with(
  title: "MiniMoonBit 2025 Programming Language Specification",
  author: "MiniMoonBit Authors",
)
#set par(first-line-indent: 0em)

#set text(font: ("EB Garamond", "Noto Serif CJK SC"), cjk-latin-spacing: auto)
#show raw: body => text(body, font: "Cascadia Code")
#show link: body => underline(body, offset: 0.3em)

#outline(title: "Table of Contents")

== Update Log

- 2025-07-18 -- Initial draft
- 2025-07-24 -- Added two versions of grammar specification

= Grammar Definition

We provide two grammar definitions for MiniMoonBit:
the `MiniMoonBitBasic` grammar definition containing only mandatory features, and
the `MiniMoonBit` grammar definition containing all optional features.

Our grammar definitions are written in ANTLR syntax.
You can also find the same content in #link("https://github.com/moonbitlang/contest-2025-data", "our repository").

== `MiniMoonBitBasic` Grammar with Basic Features

#par(first-line-indent: 0em)[
  #raw(read("MiniMoonBitBasic.g4"), syntaxes: "antlr-grammar.yml", lang: "antlr")
]

== `MiniMoonBit` Grammar with Optional Features

#par(first-line-indent: 0em)[
  #raw(read("MiniMoonBit.g4"), syntaxes: "antlr-grammar.yml", lang: "antlr")
]

== Notes

1-tuple is invalid; `(expr)` is a parenthesized expression.

= Predefined Functions

*Your program's main function should be declared as `minimbt_main`, following standard C calling convention, taking no parameters and returning nothing. You should declare it as a global symbol in assembly (`.global minimbt_main`).*

The runtime environment needs to predefine the following auxiliary functions:

```rust
// Input/output functions
/// Read an integer, return INT_MIN if failed
fn read_int() -> Int;
/// Print an integer without newline
fn print_int(i: Int) -> Unit;
/// Read a byte, return -1 if failed
fn read_char() -> Int;
/// Print a byte
fn print_char(c: Int) -> Unit;
/// Print a newline
fn print_endline() -> Unit;

// Math functions
/// Conversion between integers and floats
fn int_of_float(f: Double) -> Int;
fn float_of_int(i: Int) -> Double;
fn truncate(f: Double) -> Int;  // Same as int_of_float
/// Floating-point operations
fn floor(f: Double) -> Double;
fn abs_float(f: Double) -> Double;
fn sqrt(f: Double) -> Double;
fn sin(f: Double) -> Double;
fn cos(f: Double) -> Double;
fn atan(f: Double) -> Double;
```

We provide implementations of these functions following standard RISC-V C calling convention, with implementation names prefixed with `minimbt_`, such as `minimbt_print_int`.
During implementation, you can treat all function names not in scope as external functions, and convert them to external calls by prefixing the function name with `minimbt_`.

Additionally, to implement features like closures, arrays, and tuples, we also provide the following memory allocation functions:

```c
/// Memory allocation function
void* minimbt_malloc(int32_t size);
/// Allocate memory of corresponding size and initialize all elements to the given value
int32_t* minimbt_create_array(int32_t n_elements, int32_t init);
double* minimbt_create_float_array(int32_t n_elements, double init);
void** minimbt_create_ptr_array(int32_t n_elements, void* init);
```

You will not need to deallocate memory.

= Semantics

== Semantics

MiniMoonBit follows MoonBit's semantic rules. Since writing complete formal semantic rules may not be convenient for contestants to understand, we have not planned to provide complete formal semantic rules here.

Notable points in semantics include:

=== Expression

- MiniMoonBit has no implicit type conversion; both sides of arithmetic expressions must have the same type.

- MiniMoonBit has no mutable variables. Only array elements can be modified.

- `Array::make(n, k)` (`array_make_expr`) creates an array of length `n` where each element has value `k`. You can implement this using the `minimbt_create_{,float_,ptr_}array` functions mentioned above.

- All conditional branches of `if` statements need to return the same type. If there is no else branch, its type is always `Unit`.

=== Statement

- Functions must be declared before use. Declared functions (except `main` and `init`) can call themselves within the function body.

- All defined variable names and function names can override previous definitions.

  For example, in ```rust let a = 1; let a = 2; a```, the final value of `a` is `2`.

- A Block can have a return value. The last statement in the block can be either an expr or a stmt. If the last statement in the block is an expr, then the value of the block is the value of this expr. If the last statement in the block is a stmt and this block is an expr_stmt, then the value of the block is the value of this stmt.

  For example, ```rust let a = 1; { let b = 2; a + b }``` has value `3`, ```rust let a = 1; { let b = 2; a + b; }``` has value `3`, while ```rust let a = 1; { let b = 2; let _ = a + b; }``` has value `()`.

= LLVM IR

The evaluation system for this competition can accept two forms of submissions: RISC-V 64 assembly code and LLVM IR code. Contestants who use RISC-V 64 assembly code and pass the evaluation will receive additional points for the "register allocation" project.

For contestants who wish to submit LLVM IR code, please note that the evaluation system uses wasm to compile your compiler project, so MoonBit's official LLVM binding `llvm.mbt` cannot be used on the evaluation system. However, MoonBit officially provides another `MoonLLVM` project for this competition, which replicates a small LLVM that can generate LLVM IR code conforming to the LLVM-19 standard. The API provided by `MoonLLVM` is highly similar to `llvm.mbt` and can be directly replaced in most cases. You can use `llvm.mbt` for development in the first half of the competition to ensure generation of standard LLVM IR code, then switch to `MoonLLVM` in the second half of the competition for submission.

Please note that using `llvm.mbt` and `MoonLLVM` is not mandatory. You can also look for other LLVM IR generation libraries on Mooncakes, or implement your own LLVM IR generation tool, as long as it meets the LLVM-19 standard.

For contestants using `MoonLLVM` or using LLVM IR as intermediate code, if the final result still outputs RISC-V 64 assembly code, they can still receive additional points for the "register allocation" project.

From August 1st until the end of the competition, breaking changes in `llvm.mbt` will be given warning prompts. From August 10th until the end of the competition, breaking changes in `MoonLLVM` will be given warning prompts. During this period, some warning prompts from both projects may be directly related to the competition. After the competition ends, warning prompts related to the competition will be removed.
