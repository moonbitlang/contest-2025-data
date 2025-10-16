#import "@preview/dvdtyp:1.0.1": dvdtyp
#import "@preview/cjk-unbreak:0.1.1": remove-cjk-break-space
#import "@preview/cetz:0.3.2"
#import "@preview/cetz-plot:0.1.1"
#show: remove-cjk-break-space

#show: dvdtyp.with(title: "MiniMoonBit 2025 测试平台使用说明", author: "MiniMoonBit Authors")
#set par(first-line-indent: 0em)

#set text(font: ("New Computer Modern", "Noto Serif CJK SC"), cjk-latin-spacing: auto, lang: "zh")
#show raw: body => text(body, font: ("Cascadia Code", "Noto Sans CJK SC"))
#show link: body => underline(body, offset: 0.3em)

#outline(title: "目录")

== 更新日志

- 2025-07-09 -- 初稿
- 2025-10-16 -- 因为 `zig build-exe` 引起的一个 miscompilation, 切换到了 `clang` 和 `gcc` 进行编译。

= 代码提交方式

所有的评测提交均应在阿里云天池平台中完成。

要进行评测，请在天池平台的比赛页面中上传你的代码仓库所有文件组成的 ZIP 压缩包。
在提交之后，你的代码将会自动地被编译、运行、评测。评测结果将在你提交后不久反映在天池平台上。

为了保证评测机制的正常运行，你的项目应当位于压缩包的根目录下，且包含以下文件：

- `minimoonbit.json` -- 为 MiniMoonBit 评测机准备的一些元数据。
- `moon.mod.json` -- MoonBit 项目应当处于文件夹的根目录下。
- `src/bin/main.mbt` -- 这是编译器的主函数所在的文件，将会通过 `moon run src/bin/main.mbt` 运行。

如果你使用 Git 管理代码，
你可以通过
`git archive -o submit.zip HEAD`
获得一个包含当前 HEAD 提交的所有文件的 ZIP 压缩包。

= 元数据

为了保证我们的代码评测按照期望运行，
你在评测时需要在根目录下 `minimoonbit.json` 文件中放置一些元数据，
来告诉评测机你的代码将会如何被评测。

`minimoonbit.json` 的结构如以下 TypeScript 定义：

```ts
interface MiniMoonbitJson {
  /** 输出的代码是汇编 (asm) 还是 LLVM IR (llvm) */
  emit: 'asm' | 'llvm'
}
```

= 评测方式

你提交的代码将在沙箱环境中进行构建和评测。
代码构建环境可以访问互联网，可以通过 `moon` 下载外部程序库。
评测过程中运行的程序（包括通过 `moon run` 运行的你的编译器，以及编译生成的程序）
将无法访问互联网或任何外部资源。

如果你的程序需要输出一个非零返回值（例如类型推导失败后），
你应当使用 `panic` 或者 `abort` 来退出程序。

== 推荐使用的程序库

- #link("https://mooncakes.io/docs/moonbitlang/x", `moonbitlang/x`) 库
  提供了文件输入输出（`fs`）和命令行参数、环境变量（`sys`）的抽象，
  可以使用其进行文件输入输出和命令行参数解析。
- #link("https://mooncakes.io/docs/Yoorkin/ArgParser", `Yoorkin/ArgParser`) 提供了
  解析命令行参数的工具，可以用来解析从 `moonbitlang/x/sys` 得到的命令行参数。
- #link("https://github.com/moonbitlang/MoonLLVM", `MoonLLVM`)
  库为你提供了 LLVM IR 构建以及优化 pass 的抽象。

== 评测指令

- Typecheck:

  ```sh
  moon run src/bin/main.mbt -- --typecheck <input>
  ```

  你的程序应当读取输入文件，并运行到类型检查阶段。
  如果任意阶段失败（包括程序 parse 失败、typecheck 失败等），你的程序应当返回一个非零的返回值。

- RISC-V 代码生成/性能测试：

  ```sh
  moon run src/bin/main.mbt -- <input> -o <output>

  # 编译为 RISC-V 目标的目标文件（支持 .s 或 .ll）
  clang --target=riscv64-linux-gnu --sysroot=/usr/riscv64-linux-gnu \
    -c <output> -o <obj_file> -O2 -march=rv64gc -mabi=lp64d

  # 链接生成静态可执行文件（包含运行时）
  riscv64-linux-gnu-gcc -static -o <exe_file> <obj_file> /runtime/runtime.a \
    -O0 -march=rv64gc -mabi=lp64d -lc -lm

  # 正确性测试
  rvlinux -n <exe_file>
  # -or-
  ./<exe_file>
  ```

  - `<output>` 可以是 LLVM IR 或者汇编代码。我们会根据你传入的元数据决定输出的扩展名。

  - `rvlinux` 是 `libriscv` 提供的模拟器。我们目前使用的 fork 添加了对 stdin 的支持。
    你可以在这里找到我们目前使用的 fork：#link("https://github.com/lynzrand/libriscv")

  - 如果是需要在 RISC-V 机器上实机测试的项目，如性能测试，
    我们将会在使用 #link("https://github.com/containers/bubblewrap", `bwrap`)
    隔离后的 Linux 机器中运行你的程序。

- RISC-V 代码体积测试：

  ```sh
  moon run src/bin/main.mbt -- <input> -o <output>

  # 体积测试（对目标文件求大小）
  clang --target=riscv64-linux-gnu --sysroot=/usr/riscv64-linux-gnu \
    -c <output> -o <obj_file> -O2 -march=rv64gc -mabi=lp64d
  size <obj_file> -Gd | awk 'NR == 2 { print $1 }'   # <-- 体积测试结果

  # 正确性测试
  riscv64-linux-gnu-gcc -static -o <exe_file> <obj_file> /runtime/runtime.a \
    -O0 -march=rv64gc -mabi=lp64d -lc -lm
  rvlinux -n <exe_file>
  ```

= 评测评分说明

由于执行时间和体积都是越小越好的值，
比赛的评分标准将基于各自值的倒数。

每个评测项目的得分将会基于
评测项目值 $x$ 与基准值 $x_0$ 的比值计算：

$
  "score" = "compress"(x/x_0)
$

其中：

$
  "compress"(x) = tanh(x dot "arctanh"(1/2))
$

以下为在比值为 0 -- 5 倍时的得分比例：

#figure(caption: "得分比例图", cetz.canvas({
  import cetz.draw: *
  import cetz-plot: *

  let atanh(x) = {
    return calc.log((1 + x) / (1 - x), base: calc.e) / 2
  }
  plot.plot(
    size: (10, 5),

    x-grid: true,
    x-label: "与基准值的比值（倍）",

    y-grid: true,
    y-label: "得分比例",
    y-min: 0,
    y-max: 1,
    {
      plot.add(domain: (0, 5), x => calc.tanh(x * atanh(1 / 2)))
    },
  )
}))

= 评测结果说明

在你提交代码之后，评测平台将会对你的代码进行评测。

在天池平台上展示的评测结果将会包含以下几个部分：

- 是否成功：如果你的程序无法通过编译，整个评测将会失败
- 各分项分数：各个子项目的得分情况
- 评测日志：评测过程中的输出信息

其中，不论是否通过编译，我们都将在日志中展示你的代码的具体编译输出或错误信息。请打开日志中的链接以查看详细信息。

== 评测结果展示页面

在打开链接后，你将会看到一个类似于下图的页面，即为评测结果展示页面：

#figure(image("test-result-1.png"), caption: "评测结果展示页面")

页面的顶端为评测的元数据，包括：

- 评测队伍名和 ID
- 评测任务 ID
- 评测时间

如果你希望向我们反馈问题，请提供这些信息。

页面中间为每一评测子项目的得分情况。分项中，顶端展示了该子项目的名称、得分和总分。
在下方展示了每个测试用例的结果、名称和测试记录输出。

每个测试用例的结果可以是以下之一（并非所有状态当前均被使用）：

#table(
  columns: (auto, auto, auto),
  table.header([*简写*], [*全称*], [*说明*]),
  [`AC`], [ Accepted], [通过测试。只有获得这一结果的测试用例才会得到分数。],
  [`WA`], [ Wrong Answer], [输出不匹配预期结果。],
  [`RE`],
  [ Runtime Error],
  [运行时错误。程序运行过程中任一步骤的返回值不为 0，或者异常退出，都会得到这一结果。],

  [`TLE`],
  [ Time Limit Exceeded],
  [运行时间超过限制。你的程序运行时间超过了当前项目的限制，可能是出现了死循环。],

  [`MLE`], [ Memory Limit Exceeded], [内存使用超过限制。你的程序使用的内存超过了当前项目的限制。],
  [`OLE`], [ Output Limit Exceeded], [输出长度超过限制。你的程序输出的长度超过了当前项目的限制。],
  [`CE`], [ Compilation Error], [编译错误。你的程序无法通过编译。],
  [`OE`], [ Other Error], [其他错误。你的程序出现了其他错误。你或许可以在日志中找到更多信息。],
  [`SF`],
  [ Should Fail],
  [当前测试用例是一个反例，你的程序应当使用非零返回值（包括 panic）才能通过这个测试用例。],

  [`NA`], [ Not Available], [当前测试用例不适用于当前项目。],
)
在每个测试用例的行尾，你可以找到一个链接，点击这个链接可以查看这个测试用例的详细评测日志。隐藏测试用例将不会有这个链接。你可以在 @test-result-detail 中找到这个页面的详细说明。

#figure(image("test-result-2.png"), caption: "评测结果展示页面（底部）")

在页面底部，你可以找到你的代码的编译输出。如果你的代码无法通过编译，你可以尝试在这里找到错误信息。

== 测试用例详细日志 <test-result-detail>

#figure(image("test-details.png"), caption: "测试用例详细日志")

在这个页面中，你可以看到非隐藏测试用例测试用例的详细运行日志。

日志会包含以下内容：

- 每一步执行的命令行
- 每一步的输出（stdout 和 stderr 分别展示）
- 如果返回值不为 0，程序的返回值
- 如果标准输出不匹配预期输出，标准输出的差异
- 评测机可能提供的其他信息
