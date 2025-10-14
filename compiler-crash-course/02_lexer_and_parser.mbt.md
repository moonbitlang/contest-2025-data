# 词法分析和语法分析

在上一章的结尾，我们成功使用了 EBNF 定义了（一个极度简化版本的）MiniMoonBit 语言的语法：

```antlr
program: top_level*;
top_level: function;

// 函数
function: "fn" function_name function_body;
function_name: "main" | ident "(" param_list? ")" return_type?;
function_body: "{" expression "}";
param_list: param ("," param)*;
param: ident ":" ty;
return_type: "->" ty;

// 表达式
expression: addition | function_call | variable | int_literal;
addition: expression "+" expression;
function_call: expression "(" arg_list? ")";
arg_list: expression ("," expression)*;
variable: ident;
int_literal: number+;

// 类型
ty: "Int";
// 标识符
ident: ...;
// 数字
number: ...;
```

以及对应的抽象语法树定义：

```mbt
/// 代表整个程序
struct Program {
  top_levels : Array[TopLevel]
} derive(Show)

/// 顶层结构（函数和变量声明等等）
enum TopLevel {
  Function(func~ : Function)
} derive(Show)

/// 代表一个函数
struct Function {
  name : String
  params : Array[Param]
  return_type : Type
  body : Expression
} derive(Show)

/// 代表一个参数
struct Param {
  name : String
  ty : Type
} derive(Show)

/// 类型定义，为了简单我们就先用字符串代替吧
struct Type {
  name : String
} derive(Show)

/// 表达式定义，可能有很多种，所以我们用一个 enum 表示
enum Expression {
    /// 变量
    Variable(name~: String)
    /// 整数常量
    IntLiteral(value~: Int)
    /// 加法表达式
    Add(left~: Expression, right~: Expression)
    /// 函数调用
    Call(func~: Expression, args~: Array[Expression])
}derive(Show)
```

## 分拆词法和语法定义

你可能发现了，在上面的定义中，其实有不同抽象层级的语法混在了一起。
比如，数字字面量 `int_literal` 和标识符 `ident` 本身应该是一个整体，包含其中所有的字符而不应该被再次拆开。
也有很多在很多地方重复出现的元素，比如括号 `(` `)`、逗号 `,` 等等。

我们当然可以直接按照这个定义来分析我们的程序，然后忽略掉所有不必要的细节
（写 [解析器组合子][combinator] 的人喜欢这么做）。
但是编写计算机程序的时候抽象是很重要的一部分，所以我们通常会把程序的分析过程拆成两部分：

- [**词法分析**][lexer]（lexing）：把输入的字符序列拆分/合并成一个个的初级的 “词元”
  （token，注意不要和 AI 的同名概念混淆），以及
- [**语法分析**][parser]（parsing）：分析由这些词语组成的序列，构造出程序的语法结构。

[combinator]: https://en.wikipedia.org/wiki/Parser_combinator
[lexer]: https://en.wikipedia.org/wiki/Lexical_analysis
[parser]: https://en.wikipedia.org/wiki/Parsing

一般来说，词法分析里的词元指的是不再分拆、内部细节不重要的程序语法单位。
这个定义根据不同的编程语言、编写者的喜好，可能会有所不同，但总的来说大概在这个层级：

- 各种符号和应当看作一个整体的复合符号：`(` `)` `+` `,` `->` `!=` `{` `}` 等；
- 关键字：`fn` `let` 等；
- 字面量：数字字面量 `1234`、字符串字面量 `"hello"` 等；
- 标识符：可以用作变量名、函数名等的名字，比如 `main`、`x`、`my_variable` 等；
- 其他一些可能被直接忽略的东西，比如空白字符、注释等。

在 ANTLR 风味的 EBNF 中，我们用大写字母来表示词元的定义，而小写字母表示语法树的其余部分。
这样，我们的语法定义就可以如此拆成词法定义和语法定义两部分，
其中语法定义只会引用词法定义中定义的词元：

```antlr
// Parser rules
program: top_level*;
top_level: function;

// Functions
function: FN function_name function_body;
function_name: MAIN | IDENT LPAREN param_list? RPAREN return_type?;
function_body: LCURLYBRACKET expression RCURLYBRACKET;
param_list: param (COMMA param)*;
param: IDENT COLON ty;
return_type: ARROW ty;

// Expressions
expression: addition | function_call | variable | int_literal;
addition: expression ADD expression;
function_call: expression LPAREN arg_list? RPAREN;
arg_list: expression (COMMA expression)*;
variable: IDENT;
int_literal: NUMBER;

// Types
ty: INT;

// Lexer rules
FN: 'fn';
MAIN: 'main';
INT: 'Int';
ARROW: '->';
COMMA: ',';
LPAREN: '(';
RPAREN: ')';
LCURLYBRACKET: '{';
RCURLYBRACKET: '}';
ADD: '+';

fragment LETTER: // ANTLR 中 fragment 表示并非一个独立的词元，而只是一个词元定义的一部分
    'a' | 'b' | ... | 'z' | 'A' | 'B' | ... | 'Z' | '_';

fragment DIGIT:
    '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9';

IDENT: LETTER (LETTER | DIGIT)*;
NUMBER: DIGIT DIGIT*;
```

> 接下来的讲解跳过了很多有关语法定义的知识，而专注于实用的部分。
> 你可以查询维基百科或者编译原理教材来了解更多有关语法分析的知识。

> _我不喜欢手写这段代码，能不能用现成的工具？_
>
> 是有的。MoonBit 有 [MoonYacc][] 工具可以根据语法定义自动生成词法和语法分析器。
> 它的类似于 C/C++ 的 [Yacc][] 和 OCaml 的 [Menhir][]，但是用法有所不同。
> 请参阅这些工具的文档来了解它们的使用方法和限制。
>
> 即使你希望自动生成词法和语法分析器，
> 你也可以从下面的内容中学到很多对使用这些工具有帮助的知识，
> 例如词法语法分析的原理、声明规则的方式和注意事项等等。

[moonyacc]: https://github.com/moonbitlang/moonyacc/
[yacc]: https://en.wikipedia.org/wiki/Yacc
[menhir]: https://gallium.inria.fr/~fpottier/menhir/

## 词法分析

本节将进行一个快速的、实用的介绍，来帮助你理解词法分析的基本原理和写法。

要进行词法分析，我们先要定义一下我们产生的词元：

```mbt
enum Token {
  Fn
  Main
  IntType
  Ident(StringView)
  Number(StringView)
  LParen
  RParen
  LCurlyBracket
  RCurlyBracket
  Comma
  Colon
  Arrow
  Add

  Unknown
} derive (Show, Eq, Compare)
```

进行词法分析有很多种方法，比如使用自动或手动编写的有限状态机（Finite State Machine, FSM），
通过持续查表来进行词元的识别。
（可以参阅 [维基百科的相关章节][lexing_details]，也可以用 [MoonLex][] 等自动生成器。）
但是为了简单起见，我们在这里直接用手写的代码来进行词法分析

MoonBit 为字符串中的字串匹配提供了一些很好用的工具，可以降低我们的词法分析复杂度。
例如，我们可以通过数组样式的模式匹配快速匹配前缀和后缀，
比如 `[.."->", ..rest]` 就表示匹配前缀 `->`，剩下的部分存到 `rest` 变量中。

### 手写词法分析器

回忆一下上面提到的词法分析定义，词法分析的输入是一串字符，输出是一串词元，
我们可以将其建模成一个 `(String) -> Array[Token]` 的函数。

接下来，我们可以看一下词元的定义：
除了 `IDENT` 和 `NUMBER` 以外，剩下的词元都是固定字符串，所以可以直接从输入中按照前缀匹配。
除了这两个非固定字符串的词元的情况以外，还有一情况需要处理：
空白需要被忽略掉，不能产生任何词元。

我们先处理一下非固定的字符串的情况。
按照定义，这四种词元的开头都是不同的：

- 标识符 `IDENT` 以字母开头；
- 数字 `NUMBER` 以数字开头；
- 空白以空白字符（空格、换行）开头；

在模式匹配时，我们可以先检查这些情况，如果匹配到就进行相应的处理。
先创建几个辅助函数来分别处理已经匹配到这几种情况之后的处理方式：

```mbt
/// 处理一个以标识符开头的字符串 s
fn lex_ident(s : StringView) -> (StringView, Token) {
  // 既然已经以字母开头了，我们就从第二个字符开始继续扫描。s 一定有至少一个字符
  let starting = (try? s[1:]).unwrap()
  let rest = loop starting {
    ['0'..='9' | 'A'..='Z' | 'a'..='z' | '_', .. rest] => continue rest
    otherwise => break otherwise
  }
  // rest 是第一个不属于标识符的字符开始的 StringView
  // 因为 rest 是一个合法的 StringView，所以下面这个取 view 的方式一定不会越界
  // 或者卡在两个 UTF-16 code unit 的中间
  let token_contents = (try? s[0:rest.start_offset() - s.start_offset()]).unwrap()
  // 当然，因为 `fn`、`main`、`Int` 也是合法的标识符，所以我们在这里匹配一下
  let token = match token_contents {
    "fn" => Fn
    "main" => Main
    "Int" => IntType
    _ => Ident(token_contents)
  }
  (rest, token)
}

/// 处理一个以数字开头的字符串 s
fn lex_number(s : StringView) -> (StringView, Token) {
  // 既然已经以数字开头了，我们就从第二个字符开始继续扫描。s 一定有至少一个字符
  let starting = (try? s[1:]).unwrap()
  let rest = loop starting {
    ['0'..='9', .. rest] => continue rest
    otherwise => break otherwise
  }
  let token_contents = (try? s[0:rest.start_offset() - s.start_offset()]).unwrap()
  (rest, Number(token_contents))
}
```

我们接着就可以把这些手写的辅助函数组合起来，
加上对固定字符串的处理，写出我们的词法分析器：

```mbt
/// 词法分析器，`s` 是输入的源代码
fn lexer(s : String) -> Array[Token] {
  let out = []
  loop s[:] { // 这里我们取 s 的一个视图来方便后续匹配
    // 要跳过的东西
    // 空白
    [' ' | '\n' | '\r' | '\t', .. rest] => continue rest
    // 固定字符串
    [.. "->", .. rest] => {
      out.push(Arrow)
      continue rest
    }
    [.. ",", .. rest] => {
      out.push(Comma)
      continue rest
    }
    [.. "(", .. rest] => {
      out.push(LParen)
      continue rest
    }
    [.. ")", .. rest] => {
      out.push(RParen)
      continue rest
    }
    [.. "{", .. rest] => {
      out.push(LCurlyBracket)
      continue rest
    }
    [.. "}", .. rest] => {
      out.push(RCurlyBracket)
      continue rest
    }
    [.. "+", .. rest] => {
      out.push(Add)
      continue rest
    }
    [.. ":", .. rest] => {
      out.push(Colon)
      continue rest
    }

    // 非固定字符串
    ['A'..='Z' | 'a'..='z' | '_', ..] as s => {
      let (rest, token) = lex_ident(s)
      out.push(token)
      continue rest
    }
    ['0'..='9', ..] as s => {
      let (rest, token) = lex_number(s)
      out.push(token)
      continue rest
    }

    // 到达文件尾部
    [] => break
    [_unk, .. rest] => {
      // 如果遇到无法识别的字符，我们就跳过它
      // 当然你也可以选择报错
      out.push(Unknown)
      continue rest
    }
  }
  out
}
```

一个简单的词法分析器就这样写好了。
我们写的可以算是一个控制流实现的有限状态机，
每次循环都从输入中逐字符地匹配，直到匹配到一个词元或者跳过一些空白字符。

另外需要注意的一点是，一般来说词法分析都是按照最长匹配原则进行的。
也就是说，对于任意一个词元，我们一般都要尽可能多地把输入字符包含进来，
比如 `mainly` 应该被识别成一个标识符 `mainly`，而不是 `main` 加上一个标识符 `ly`。

我们可以测试一下：

```mbt
test {
  let src = "fn main { 123 + 456 }"
  let tokens = lexer(src)
  inspect(tokens, content=(
    #|[Fn, Main, LCurlyBracket, Number("123"), Add, Number("456"), RCurlyBracket]
  ))
}
```

[lexing_details]: https://en.wikipedia.org/wiki/Lexical_analysis#Details
[moonlex]: https://github.com/moonbitlang/moonlex

## 语法分析

在获得了对应于原始程序的词元列表之后，我们就可以进行语法分析了。
语法分析有很多种类，但是主要可以分为自顶向下和自底向上两个门派。

[自顶向下分析][td]是按照语法定义的结构，从最开始的符号（在我们的例子中是 `program`）开始，
一步步地按照现有的词元列表向下展开，直到每个符号都被替换成词元为止。
[自底向上分析][bu]则是从词元开始，尝试一步步地把词元合并成更高层次的语法结构，直到合并成 `program` 为止。
两种方法都有各自的优缺点和适用范围，并没有绝对的好坏之分。

[td]: https://en.wikipedia.org/wiki/Top-down_parsing
[bu]: https://en.wikipedia.org/wiki/Bottom-up_parsing

在这篇快速入门教程中，我们将介绍一种非常简单、且适合手写的自顶向下分析方法，
称为[递归下降][rd]（Recursive Descent）。

递归下降的思想很简单：
为语法中的每个符号（非终结符）编写一个函数，
在这个函数的内部检查接下来的词元是否符合这个符号的定义，
如果符合就把这些词元消耗掉，并返回对应的抽象语法树节点。
如果不符合，就报错。

[rd]: https://en.wikipedia.org/wiki/Recursive_descent_parser

我们接下来就来写一个简单的递归下降语法分析器。

### 准备工作

我们的递归下降分析器是工作在一个词元（Token）的迭代器上的。
分析器每次可以向前看一个词元来决定下一步分析的语法元素是什么。

在这里，我们先定义一下分析器的本体，以及一些基本的操作：
向前看一个词元、读入一个词元、判断是否到达末尾。

```mbt
/// 一个极简的递归下降语法分析器
struct Parser {
  tokens : Array[Token]
  mut pos : Int
}

fn Parser::new(tokens : Array[Token]) -> Parser {
  Parser::{ tokens, pos: 0 }
}

/// 判断是否已经到达词元流的末尾
fn Parser::is_eof(self : Parser) -> Bool {
  self.pos >= self.tokens.length()
}

/// 向前看一个词元，但是不读入它
fn Parser::peek(self : Parser) -> Token? {
  if self.is_eof() { None } else { Some(self.tokens[self.pos]) }
}

/// 读入一个词元
fn Parser::advance(self : Parser) -> Token raise ParseError {
  match self.peek() {
    None => raise UnexpectedEof
    Some(t) => {
      self.pos += 1
      t
    }
  }
}
```

当然，分析语法的时候总会遇到错误，
所以我们还需要定义一些错误类型：

```mbt
suberror ParseError {
  /// 我想要某个词元，但是下一个词元不是它
  Expected(Token)
  /// 下一个词元不是我想要的
  Unexpected(Token, when~: String)
  /// 程序结构没有写完就终止了
  UnexpectedEof
  /// 数字转换失败
  IntParseFailed(Token, @strconv.StrConvError)
} derive (Show)
```

> 如果你好奇为什么它可以只看一个词元就决定下一步的话，
> 这是因为我们给出的示例语法基本上属于一种 [LL(1) 语法][ll1]。
> 这个名字的意思是它可以被 LL(1) 的语法分析器处理，
> 而 LL(1) 的意思是：
>
> - `L` -- 从左到右扫描输入，也就是我们正常的阅读顺序；
> - `L` -- 每次从最左边的非终结符开始展开（也就是自顶向下）；
> - `1` -- 最多向前看 1 个词元来决定下一步的动作。
>
> LL(1) 语法需要满足一些限制条件，在这里我们就不展开讲了。
> 如果你对这个概念感兴趣，可以查看维基百科和编译教材的相关章节。

[ll1]: https://en.wikipedia.org/wiki/LL_parser

### 一些辅助函数

要想分析器写得爽，我们还需要一点点其他的辅助函数。
因为语法中有很多固定的符号（想想 `fn`、`(`、`+` 等等），
我们不会想每次遇到它们都写一堆 `if`/`match` 语句来判断读进来的正不正确。

```mbt
/// 如果下一个词元是指定的符号，就消费掉并返回 true，否则返回 false
fn Parser::eat_symbol(self : Parser, sym : Token) -> Bool {
  if self.peek() == Some(sym) {
    (try? self.advance()) |> ignore
    true
  } else {
    false
  }
}

/// 读取一个标识符；返回标识符字符串（也兼容 main）
fn Parser::read_ident(self : Parser) -> String raise ParseError {
  match self.advance() {
    Ident(view) => view.to_string()
    Main => "main"
    t => raise Unexpected(t, when="reading identifier")
  }
}
```

### 你的第一个递归下降函数

我们先从语法中最简单的 `ty` 开始吧。它的定义是：

```antlr
ty: INT;
```

`ty` 只有一种展开方式，就是 `INT` 这个词元。
我们直接读取下一个词元，然后判断它是不是 `Int` 就行了。

```mbt
/// 读取一个类型
fn Parser::parse_type(self : Parser) -> Type raise ParseError {
  match self.advance() {
    IntType => Type::{ name: "Int" }
    t => raise Unexpected(t, when="reading type")
  }
}
```

我们也可以试一下解析更长的语法，比如一个函数参数：

```antlr
param: IDENT COLON ty;
```

这里，我们要依次读取三个词元：一个标识符、一个冒号和一个类型。
写成函数是这样的：

```mbt
fn Parser::parse_param(self: Parser) -> Param raise ParseError{
  // 读取一个标识符
  let name = self.read_ident()
  // 读取一个冒号
  if !self.eat_symbol(Colon) {
    raise Expected(Colon)
  }
  // 调用解析类型的函数，读取一个类型
  let ty = self.parse_type()
  Param::{ name, ty }
}
```

注意到我们直接调用了 `self.parse_type()` 来解析类型。
这就是递归下降解析中 “递归” 指的东西——每一个非终结符都有一个对应的函数，
这些函数可以相互调用来完成更复杂的解析任务。

```antlr
// TODO: remove me
// Parser rules
program: top_level*;
top_level: function;

// Functions
function: FN function_name function_body;
function_name: MAIN | IDENT LPAREN param_list? RPAREN return_type?;
function_body: LCURLYBRACKET expression RCURLYBRACKET;
param_list: param (COMMA param)*;
return_type: ARROW ty;

// Expressions
expression: addition | function_call | variable | int_literal;
addition: expression ADD expression;
function_call: expression LPAREN arg_list? RPAREN;
arg_list: expression (COMMA expression)*;
variable: IDENT;
int_literal: NUMBER;
```

### 解析表达式

#### 表达式的结合性

其实，我们之前定义的语法有一个错误：
我们定义的表达式并不能被 LL(1) 分析器解析！
问题出在哪里呢？让我们看一下表达式的定义：

```antlr
expression: addition | function_call | variable | int_literal;
addition: expression ADD expression;
```

注意 `addition` 这个符号，我们可以如此展开：

```
   expression
-> addition
-> expression ADD expression
-> addition ADD expression
-> expression ADD expression ADD expression
-> ...
```

发现了吗？最左边的部分永远也展开不完！

如果我们采用朴素的递归下降方法来解析这个语法的话，
我们永远可以在解析最左边的 expression 的时候继续展开 addition，
子子孙孙无穷匮也，最后撑爆调用栈。
这种情况被称作[左递归][lrecursion] (left recursion)，
是 LL(_k_) 分析器无法处理的情况之一。

[lrecursion]: https://en.wikipedia.org/wiki/Left_recursion

为了解决这个问题，我们需要对 `expression` 做一些变换。

还记在小学的时候，我们学过加减法的结合律吗？
我们知道，`a + b + c` 等价于 `(a + b) + c` 和 `a + (b + c)`。
这两种结合方式，在这里分别称为[左结合和右结合][assoc]。

[assoc]: https://en.wikipedia.org/wiki/Associative_property

用 `#` 代表一个任意的运算符，我们称：

- `a # b # c == (a # b) # c` 是左结合
- `a # b # c == a # (b # c)` 是右结合

当然，对于加法来说这个结合的方向是无所谓的，因为加法满足交换律。
但是对于减法，`a - b - c` 只等价于 `(a - b) - c`，不等价于 `a - (b - c)`；
对除法也是一样的。
所以，在计算机程序中为了统一，我们一般规定四则运算都是左结合的。

结合性要配合运算优先级才能起到简化语法的作用。
所以接下来我们也要处理运算优先级的问题。

#### 表达式的优先级

你可能也还记得在小学的时候学到的四则运算的优先级：
乘法比加法优先级高，括号里面的东西要先算，等等。
我们当然也要教会我们的解析器这些规则。

再次观察我们的表达式定义：

```antlr
expression: addition | function_call | variable | int_literal;
```

优先级从高到低可以分为三个部分：

- `variable` 和 `int_literal` 是最简单的表达式，不能再分了；
- `function_call` 的优先级低于上两个，同时它可以接在上两个表达式的后面；
- `addition` 的优先级最低。

这样，我们可以把表达式的定义拆成三层：

```antlr
// 优先级最高
primary: int_literal | variable;
// 优先级第二
postfix: function_call;
function_call: primary "(" arg_list? ")";
// 优先级最低
expression: addition;
addition: postfix "+" expression;
```

这样，每个定义最左边的符号只会展开到比它优先级更高的符号上去，
避免了左递归的问题。

表达式的每一层优先级当然也可以选择跳过这一层优先级的表达式，
直接解析更高优先级的表达式。
让我们把它也加上：

```antlr
// 优先级最高
primary: int_literal | variable;
// 优先级第二
postfix: function_call | primary;
function_call: primary "(" arg_list? ")";
// 优先级最低
expression: addition | postfix;
addition: postfix "+" expression;
```

这又带来了一个问题：在解析 `expression` 的时候，
因为两种展开方式都是 `postfix` 开头的，
我怎么知道下一步在里面要解析的是 `addition` 还是 `postfix` 呢？
为了解决这个问题，我们可以对这个定义再进行一次变形，把递归展开变成循环：

```antlr
// 优先级最高
primary: int_literal | variable;
// 优先级第二
postfix: primary ( "(" arg_list? ")" )*;
// 优先级最低
expression: postfix ( "+" postfix )*;
```

这样就避免了上面的问题：
解析 `postfix` 的时候，只有看见了左括号 `(` 才进入函数调用的解析，
对于 `expression` 也是同理。

#### 实现表达式解析

说了这么多，该实操了。
模仿之前递归下降的写法，我们可以直接把上面的定义翻译成代码：

```mbt
/// primary: int_literal | variable
fn Parser::parse_primary(self : Parser) -> Expression raise ParseError {
  match self.peek() {
    Some(Number(digits)) => {
      let _ = self.advance()
      Expression::IntLiteral(value=@strconv.parse_int(digits, base=10)) catch {
        StrConvError(_) as e => raise IntParseFailed(Number(digits), e)
      }
    }
    Some(Ident(_)) | Some(Main) => {
      let name = self.read_ident()
      Expression::Variable(name~)
    }
    Some(t) => {
      let _ = self.advance()
      raise Unexpected(t, when="reading primary expression")
    }
    None => raise UnexpectedEof
  }
}

/// 解析后缀（函数调用）
fn Parser::parse_postfix(self : Parser) -> Expression raise ParseError {
  let mut expr = self.parse_primary()
  while true {
    // 对应 ( '(' ... )* 的开头，这是个循环
    if self.eat_symbol(LParen) {
      // arg_list?
      let args : Array[Expression] = match self.peek() {
        Some(RParen) => {
          let _ = self.advance() // consume ')'
          []
        }
        _ => {
          let args0 = {
            let a = self.parse_expression()
            let xs = []
            let _ = xs.push(a)
            xs
          }
          let args_acc = {
            let xs = args0
            while self.eat_symbol(Comma) {
              xs.push(self.parse_expression())
            }
            xs
          }
          if !self.eat_symbol(RParen) {
            raise Expected(RParen)
          }
          args_acc
        }
      }
      expr = Expression::Call(func=expr, args~)
    } else {
      break
    }
  }
  expr
}

/// 左结合加法：E (+ E)*
fn Parser::parse_addition(self : Parser) -> Expression raise ParseError {
  let mut lhs = self.parse_postfix()
  while self.eat_symbol(Add) {
    let rhs = self.parse_postfix()
    lhs = Expression::Add(left=lhs, right=rhs)
  }
  lhs
}

fn Parser::parse_expression(self : Parser) -> Expression raise ParseError {
  self.parse_addition()
}
```

> 解决左递归和优先级的方法其实并不止一种。
> 举个例子，[Pratt Parsing](https://www.moonbitlang.cn/pearls/pratt-parse)
> 也是一种很常见的解析表达式的方法。
> 它的解决方式比起 LL 更像 LR，会在一个函数里从底向上解析所有优先级的表达式。
> 这也是使用递归下降的好处之一——只要能写出正确的代码，它并不关心你用了什么范式。

### 解析函数定义

剩下的语法就很简单了，我们直接照着定义写就行了。

```mbt
/// param_list: param (',' param)*
fn Parser::parse_param_list(self : Parser) -> Array[Param] raise ParseError {
  let params = []
  // 至少一个
  let _ = params.push(self.parse_param())
  while self.eat_symbol(Comma) {
    params.push(self.parse_param())
  }
  params
}

/// function_name: MAIN | IDENT '(' param_list? ')' return_type?
fn Parser::parse_function_name_and_sig(
  self : Parser,
) -> (String, Array[Param], Type) raise ParseError {
  match self.peek() {
    Some(Main) => {
      let _ = self.advance()
      ("main", [], Type::{ name: "Int" })
    }
    Some(Ident(_)) => {
      let name = self.read_ident()
      if !self.eat_symbol(LParen) {
        raise Expected(LParen)
      }
      let params : Array[Param] = if self.eat_symbol(RParen) {
        []
      } else {
        let ps = self.parse_param_list()
        if !self.eat_symbol(RParen) {
          raise Expected(RParen)
        }
        ps
      }
      // return_type?
      let ret_ty = if self.eat_symbol(Arrow) {
        self.parse_type()
      } else {
        // 缺省：Int
        Type::{ name: "Int" }
      }
      (name, params, ret_ty)
    }
    Some(t) => {
      let _ = self.advance()
      raise Unexpected(t, when="Parsing function")
    }
    None => raise UnexpectedEof
  }
}

/// function: 'fn' function_name function_body
fn Parser::parse_function(self : Parser) -> Function raise ParseError {
  let tok = self.advance()
  match tok {
    Fn => ()
    t => raise Unexpected(t, when="parsing function")
  }
  let (name, params, return_type) = self.parse_function_name_and_sig()
  // function_body: '{' expression '}'
  if !self.eat_symbol(LCurlyBracket) {
    raise Expected(LCurlyBracket)
  }
  let body = self.parse_expression()
  if !self.eat_symbol(RCurlyBracket) {
    raise Expected(RCurlyBracket)
  }
  Function::{ name, params, return_type, body }
}

/// program: top_level*
fn Parser::parse_program(self : Parser) -> Program raise ParseError {
  let tops = []
  while !self.is_eof() {
    let func = self.parse_function()
    tops.push(TopLevel::Function(func~))
  }
  Program::{ top_levels: tops }
}

/// 入口函数
fn parse(tokens: Array[Token]) -> Program raise ParseError {
  Parser::new(tokens).parse_program()
}
```

到这里，我们的递归下降解析器就写完了。
可以看到，主要都是体力活，做完合适的变换直接照着定义写就行了。

### 测试一下

我们可以测试一下这个解析器的可用性：

```mbt
test "parse main" {
  let src = "fn main { 1 }"
  let tokens = lexer(src)

  inspect(tokens, content=(
    #|[Fn, Main, LCurlyBracket, Number("1"), RCurlyBracket]
  ))

  let prog = parse(tokens)
  inspect(prog, content=(
    #|{top_levels: [Function(func={name: "main", params: [], return_type: {name: "Int"}, body: IntLiteral(value=1)})]}
  ))
}


///|
test "parse function with params and addition" {
  let src = "fn add(x: Int, y: Int) -> Int { x + y }"
  let tokens = lexer(src)
  inspect(
    tokens,
    content=(
      #|[Fn, Ident("add"), LParen, Ident("x"), Colon, IntType, Comma, Ident("y"), Colon, IntType, RParen, Arrow, IntType, LCurlyBracket, Ident("x"), Add, Ident("y"), RCurlyBracket]
    ),
  )
  let prog = parse(tokens)
  inspect(
    prog,
    content=(
      #|{top_levels: [Function(func={name: "add", params: [{name: "x", ty: {name: "Int"}}, {name: "y", ty: {name: "Int"}}], return_type: {name: "Int"}, body: Add(left=Variable(name="x"), right=Variable(name="y"))})]}
    ),
  )
}
```

到这为止，我们就成功地实现了一个简单的词法分析器和递归下降语法分析器，
可以将 MiniMoonBit 语言的源代码解析成抽象语法树了。
