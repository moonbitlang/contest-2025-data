#import "@preview/dvdtyp:1.0.1": dvdtyp
#import "@preview/cjk-unbreak:0.1.1": remove-cjk-break-space
#import "@preview/cetz:0.3.2"
#import "@preview/cetz-plot:0.1.1"
#show: remove-cjk-break-space

#show: dvdtyp.with(
  title: "MiniMoonBit 2025 Testing Platform Usage Guide",
  author: "MiniMoonBit Authors",
)
#set par(first-line-indent: 0em)

#set text(font: ("EB Garamond", "Noto Serif CJK SC"), cjk-latin-spacing: auto, lang: "zh")
#show raw: body => text(body, font: ("Cascadia Code", "Noto Sans CJK SC"))
#show link: body => underline(body, offset: 0.3em)

#outline(title: "Table of Contents")

== Update Log

- 2025-07-09 -- Initial draft
- 2025-10-16 -- Switched from Zig-based build to clang/gcc due to a miscompilation in `zig build-exe`.

= Code Submission Method

All evaluation submissions should be completed on the Alibaba Cloud Tianchi platform.

To perform evaluation, please upload a ZIP compressed file containing all files from your code repository on the competition page of the Tianchi platform.
After submission, your code will be automatically compiled, executed, and evaluated. The evaluation results will be reflected on the Tianchi platform shortly after your submission.

To ensure the normal operation of the evaluation mechanism, your project should be located in the root directory of the compressed file and contain the following files:

- `minimoonbit.json` -- Some metadata prepared for the MiniMoonBit evaluation system.
- `moon.mod.json` -- The MoonBit project should be in the root directory of the folder.
- `src/bin/main.mbt` -- This is the file where the compiler's main function is located, which will be run via `moon run src/bin/main.mbt`.

If you use Git to manage your code,
you can obtain a ZIP compressed file containing all files from the current HEAD commit through
`git archive -o submit.zip HEAD`.

= Metadata

To ensure our code evaluation runs as expected,
you need to place some metadata in the `minimoonbit.json` file in the root directory during evaluation
to tell the evaluation system how your code will be evaluated.

The structure of `minimoonbit.json` is as defined in the following TypeScript:

```ts
interface MiniMoonbitJson {
  /** Whether the output code is assembly (asm) or LLVM IR (llvm) */
  emit: 'asm' | 'llvm'
}
```

= Evaluation Method

Your submitted code will be built and evaluated in a sandbox environment.
The code build environment can access the internet and can download external libraries through `moon`.
Programs running during the evaluation process (including your compiler run through `moon run` and the compiled programs)
will not be able to access the internet or any external resources.

If your program needs to output a non-zero return value (for example, after type inference failure),
you should use `panic` or `abort` to exit the program.

== Recommended Libraries

- The #link("https://mooncakes.io/docs/moonbitlang/x", `moonbitlang/x`) library
  provides abstractions for file input/output (`fs`) and command-line arguments and environment variables (`sys`),
  which can be used for file input/output and command-line argument parsing.
- #link("https://mooncakes.io/docs/Yoorkin/ArgParser", `Yoorkin/ArgParser`) provides
  tools for parsing command-line arguments, which can be used to parse command-line arguments obtained from `moonbitlang/x/sys`.
- The #link("https://github.com/moonbitlang/MoonLLVM", `MoonLLVM`)
  library provides abstractions for LLVM IR construction and optimization passes.

== Evaluation Commands

- Typecheck:

  ```sh
  moon run src/bin/main.mbt -- --typecheck <input>
  ```

  Your program should read the input file and run to the type checking stage.
  If any stage fails (including program parse failure, typecheck failure, etc.), your program should return a non-zero return value.

- RISC-V code generation/performance testing:

  ```sh
  moon run src/bin/main.mbt -- <input> -o <output>

  # Compile RISC-V target object (supports .s or .ll)
  clang --target=riscv64-linux-gnu --sysroot=/usr/riscv64-linux-gnu -c <output> -o <obj_file> -O2 -march=rv64gc -mabi=lp64d

  # Link a static executable (including runtime)
  riscv64-linux-gnu-gcc -static -o <exe_file> <obj_file> /runtime/runtime.a -O0 -march=rv64gc -mabi=lp64d -lc -lm

  # Correctness testing
  rvlinux -n <exe_file>
  # -or-
  ./<exe_file>
  ```

  - `<output>` can be LLVM IR or assembly code. We will determine the output extension based on the metadata you provide.

  - `rvlinux` is a simulator provided by `libriscv`. Our current fork adds support for stdin.
    You can find our current fork here: #link("https://github.com/lynzrand/libriscv")

  - For projects that need to be tested on actual RISC-V machines, such as performance testing,
    we will run your program on a Linux machine isolated using #link("https://github.com/containers/bubblewrap", `bwrap`).

- RISC-V code size testing:

  ```sh
  moon run src/bin/main.mbt -- <input> -o <output>

  # Size testing (on the object file)
  clang --target=riscv64-linux-gnu --sysroot=/usr/riscv64-linux-gnu -c <output> -o <obj_file> -O2 -march=rv64gc -mabi=lp64d
  size <obj_file> -Gd | awk 'NR == 2 { print $1 }'   # <-- Size test result

  # Correctness testing (optional)
  riscv64-linux-gnu-gcc -static -o <exe_file> <obj_file> /runtime/runtime.a -O0 -march=rv64gc -mabi=lp64d -lc -lm
  rvlinux -n <exe_file>
  ```

= Evaluation Scoring Explanation

Since both execution time and size are values where smaller is better,
the competition scoring criteria will be based on the reciprocal of their respective values.

The score for each evaluation item will be calculated based on
the ratio of evaluation item value $x$ to baseline value $x_0$:

$
  "score" = "compress"(x/x_0)
$

where:

$
  "compress"(x) = tanh(x dot "arctanh"(1/2))
$

The following shows the score ratio when the ratio is 0 -- 5 times:

#figure(caption: "Score Ratio Chart", cetz.canvas({
  import cetz.draw: *
  import cetz-plot: *

  let atanh(x) = {
    return calc.log((1 + x) / (1 - x), base: calc.e) / 2
  }
  plot.plot(
    size: (10, 5),

    x-grid: true,
    x-label: "Ratio to baseline value (times)",

    y-grid: true,
    y-label: "Score ratio",
    y-min: 0,
    y-max: 1,
    {
      plot.add(domain: (0, 5), x => calc.tanh(x * atanh(1 / 2)))
    },
  )
}))

= Evaluation Results Explanation

After you submit your code, the evaluation platform will evaluate your code.

The evaluation results displayed on the Tianchi platform will include the following parts:

- Success status: If your program cannot compile successfully, the entire evaluation will fail
- Sub-item scores: Scoring situation for each sub-project
- Evaluation log: Output information during the evaluation process

Regardless of whether compilation is successful, we will display the specific compilation output or error information of your code in the log. Please open the link in the log to view detailed information.

== Evaluation Results Display Page

After opening the link, you will see a page similar to the figure below, which is the evaluation results display page:

#figure(image("test-result-1.png"), caption: "Evaluation Results Display Page")

The top of the page contains evaluation metadata, including:

- Evaluation team name and ID
- Evaluation task ID
- Evaluation time

If you wish to report problems to us, please provide this information.

The middle of the page shows the scoring situation for each evaluation sub-project. In the sub-items, the top displays the name, score, and total score of the sub-project.
Below shows the results, names, and test record outputs for each test case.

The result of each test case can be one of the following (not all statuses are currently used):

#table(
  columns: (auto, auto, auto),
  table.header([*Abbreviation*], [*Full Name*], [*Description*]),
  [`AC`], [ Accepted], [Test passed. Only test cases with this result will receive points.],
  [`WA`], [ Wrong Answer], [Output does not match expected result.],
  [`RE`],
  [ Runtime Error],
  [Runtime error. Any step during program execution returning a non-zero value, or abnormal exit, will result in this status.],

  [`TLE`],
  [ Time Limit Exceeded],
  [Runtime exceeded limit. Your program's runtime exceeded the current project's limit, possibly due to an infinite loop.],

  [`MLE`],
  [ Memory Limit Exceeded],
  [Memory usage exceeded limit. Your program's memory usage exceeded the current project's limit.],

  [`OLE`],
  [ Output Limit Exceeded],
  [Output length exceeded limit. Your program's output length exceeded the current project's limit.],

  [`CE`], [ Compilation Error], [Compilation error. Your program could not compile successfully.],
  [`OE`],
  [ Other Error],
  [Other error. Your program encountered other errors. You may find more information in the log.],

  [`SF`],
  [ Should Fail],
  [The current test case is a negative example; your program should use a non-zero return value (including panic) to pass this test case.],

  [`NA`], [ Not Available], [The current test case is not applicable to the current project.],
)
At the end of each test case row, you can find a link. Clicking this link allows you to view the detailed evaluation log for this test case. Hidden test cases will not have this link. You can find a detailed description of this page in @test-result-detail.

#figure(image("test-result-2.png"), caption: "Evaluation Results Display Page (Bottom)")

At the bottom of the page, you can find the compilation output of your code. If your code cannot compile successfully, you can try to find error information here.

== Test Case Detailed Log <test-result-detail>

#figure(image("test-details.png"), caption: "Test Case Detailed Log")

On this page, you can see the detailed execution log for non-hidden test cases.

The log will include the following content:

- Command line executed for each step
- Output from each step (stdout and stderr displayed separately)
- If the return value is not 0, the program's return value
- If standard output does not match expected output, differences in standard output
- Other information the evaluation system may provide
