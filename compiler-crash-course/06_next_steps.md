# 后面的工作

首先，恭喜你看完这篇快速入门教程！

前面五章的内容，大致相当于对半个学期的大学编译原理课进行串讲。
当然，为了文章比较精简，我们跳过了不少内容，比如各种定义的演变过程。
但是，现有的内容应该也足够你写出 MiniMoonBit 编译器在代码生成之前的所有部分了。

**首先指个路：如果你想写关于代码生成的部分，你可以看 [LLVM.mbt 的代码生成教程][tutorial]。
虽然因为比赛的限制，你不能直接使用 LLVM.mbt 生成代码，
但是推荐使用的 LLVM IR 生成工具 [MoonLLVM][] 的接口几乎是一样的。**

[tutorial]: https://github.com/moonbitlang/llvm.mbt/blob/master/tutorial/Chapter0.mbt.md
[moonllvm]: https://github.com/moonbitlang/MoonLLVM

## 编译教材

编译原理这个学科本身当然远没有我们看到的这么简单。

从计算机发明起，就有无数的学者和工程师前赴后继试图让代码跑得更快。
这些工程师的经验经过后人总结，就成了我们看到的无数编译原理教材。
我们下面会按照类型分别推荐一些教材供你继续阅读。

### 综合教材

- **Compilers: Principles, Techniques, and Tools (2nd ed.)**（龙书）-- [出版社页面](https://www.pearson.com/en-us/subject-catalog/p/compilers-principles-techniques-and-tools/P200000003433/9780321486813) -- 理论全面权威，但工程实践部分较旧
- **Engineering a Compiler (3rd ed.)** -- [出版社页面](https://shop.elsevier.com/books/engineering-a-compiler/cooper/978-0-12-815412-0) -- 工程导向，现代优化技术讲解清晰
- **Modern Compiler Implementation in ML/Java/C**（Tiger Book/虎书）-- [官网与资源](https://www.cs.princeton.edu/~appel/modern/) -- 手把手实现完整编译器，实践性强
- Crafting Interpreters -- [在线书](https://craftinginterpreters.com/) -- 轻松上手，前后端与运行时概念讲解清晰

### 大学课程

- **Stanford CS143: Compilers** -- [课程主页](https://web.stanford.edu/class/cs143/) -- 经典的入门课程，实验扎实
- **Compilers (Coursera, Alex Aiken)** -- [课程主页](https://www.coursera.org/learn/compilers) -- CS143 的在线版本，适合自学
- **MIT 6.035: Computer Language Engineering** -- [课程主页](http://web.mit.edu/6.035/www/) -- 侧重代码分析与优化，对实验要求更高
- UC Berkeley CS164: Programming Languages and Compilers -- [课程主页](https://cs164.org/) -- 覆盖语言设计与实现的广泛主题

### 前端（语法解析）

- **The Definitive ANTLR 4 Reference** -- [图书主页](https://pragprog.com/titles/tpantlr2/the-definitive-antlr-4-reference/) -- 强大的解析器生成器 ANTLR 的权威指南
- **Parsing Techniques: A Practical Guide (2nd ed.)** -- [出版社页面](https://link.springer.com/book/10.1007/978-0-387-68954-8) -- 对各类解析算法的全面综述
- Flex & Bison -- [图书主页](https://www.oreilly.com/library/view/flex-bison/9780596805418/) -- 传统的 Lex/Yacc 工具链教材
- Parsing Expression Grammars: A Recognition-Based Syntactic Foundation (2004) -- [PDF](https://bford.info/pub/lang/peg.pdf) -- PEG 的奠基性论文

### 类型理论

- **Types and Programming Languages (TAPL)** -- [主页](https://www.cis.upenn.edu/~bcpierce/tapl/) -- 类型系统领域的“圣经”
- **Practical Foundations for Programming Languages (PFPL)** -- [主页](https://www.cs.cmu.edu/~rwh/pfpl.html) -- 以更根本的视角审视语言特性
- **Programming Language Foundations in Agda (PLFA)** -- [在线书](https://plfa.inf.ed.ac.uk/) -- 通过 Agda 学习类型论，实践性强
- Certified Programming with Dependent Types (CPDT) -- [在线书](http://adam.chlipala.net/cpdt/) -- 在 Coq 中进行形式化验证的入门

### 代码优化

- **Advanced Compiler Design and Implementation** -- [出版社页面](https://shop.elsevier.com/books/advanced-compiler-design-and-implementation/muchnick/978-0-08-049871-3) -- 优化技术“百科全书”
- **Optimizing Compilers for Modern Architectures: A Dependence-based Approach** -- [出版社页面](https://shop.elsevier.com/books/optimizing-compilers-for-modern-architectures/allen/978-0-08-051324-9) -- 专攻循环优化与并行化
- LLVM Language Reference Manual -- [文档](https://llvm.org/docs/LangRef.html) -- 实现 LLVM 优化的权威参考

### 代码生成

- **LLVM Kaleidoscope Tutorial** -- [教程](https://llvm.org/docs/tutorial/) -- 学习 LLVM IR 生成的“Hello World”
- **Linkers and Loaders** -- [主页](http://www.iecc.com/linker/) -- 深入了解编译的最后一步
- A Retargetable C Compiler: Design and Implementation (LCC) -- [项目主页](https://github.com/drh/lcc) -- 一个简洁但完整的可重定目标编译器
- RISC-V Unprivileged ISA Specification -- [规范](https://github.com/riscv/riscv-isa-manual) -- 针对 RISC-V 架构的权威指令集手册

### 杂项

- **The Garbage Collection Handbook** -- [主页](https://gchandbook.org/) -- 自动内存管理的权威参考
- LLVM Programmer’s Manual -- [文档](https://llvm.org/docs/ProgrammersManual.html) -- 编写 LLVM Pass 的必读手册
- GCC Internals -- [文档](https://gcc.gnu.org/onlinedocs/gccint/) -- 了解 GCC 内部实现的参考
- Writing an Interpreter in Go / Writing a Compiler in Go -- [官网](https://interpreterbook.com/) / [官网](https://compilerbook.com/) -- 轻量、快速的实战项目
