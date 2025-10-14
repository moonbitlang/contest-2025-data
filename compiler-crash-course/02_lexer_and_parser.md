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
function_call: ident "(" arg_list? ")";
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

## 分拆词法和语法定义

你可能发现了，在上面的定义中，其实有不同抽象层级的语法混在了一起。
比如，数字字面量 `int_literal` 和标识符 `ident` 本身应该是一个整体，包含其中所有的字符而不应该被再次拆开。
也有很多在很多地方重复出现的元素，比如括号 `(` `)`、逗号 `,` 等等。

我们当然可以直接按照这个定义来分析我们的程序，然后忽略掉所有不必要的细节
（写 [解析器组合字][combinator] 的人喜欢这么做）。
但是编写计算机程序的时候抽象是很重要的一部分，所以我们通常会把程序的分析过程拆成两部分：

- [**词法分析**][lexer]（lexing）：把程序拆成一个个的初级的 “词元”（token，注意不要和 AI 的同名概念混淆），以及
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
function_call: IDENT LPAREN arg_list? RPAREN;
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

## 词法分析

## 语法分析
