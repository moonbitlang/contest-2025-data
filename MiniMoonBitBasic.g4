grammar MiniMoonBit;

prog: top_level* EOF;

// Top-level
// 
// Top level declarations should start at the beginning of the line, i.e.
// token.column == 0. Since this is non-context-free, it is not included in this
// backend-agnostic ANTLR grammar.
top_level: top_let_decl | toplevel_fn_decl;
top_let_decl:
	'let' IDENTIFIER (':' type)? '=' expr ';';
toplevel_fn_decl: (main_fn_decl | top_fn_decl);

// Function declarations
// 
// `fn main` does not accept parameters and return type
main_fn_decl: 'fn' 'main' fn_body;

top_fn_decl:
	'fn' IDENTIFIER '(' param_list? ')' '->' type fn_body;
param_list: param (',' param)*;
param: IDENTIFIER type_annotation;
fn_body: '{' stmt* expr? '}';

nontop_fn_decl:
	'fn' IDENTIFIER '(' nontop_param_list? ')' (
		'->' type
	)? fn_body;
nontop_param_list:
	nontop_param (',' nontop_param)*;
nontop_param: IDENTIFIER type_annotation?;

// Statements
stmt:
	let_tuple_stmt
	| let_stmt
	| fn_decl_stmt
	| assign_stmt
	| while_stmt
	| return_stmt
	| expr_stmt;

let_tuple_stmt:
	'let' '(' IDENTIFIER (',' IDENTIFIER)* ')' type_annotation? '=' expr ';' ;
let_stmt:
	'let' 'mut'? IDENTIFIER type_annotation? '=' expr ';';
type_annotation: COLON type;

fn_decl_stmt: nontop_fn_decl;

// x[y] = z;
assign_stmt: left_value '=' expr ';';

// while x { ... }
while_stmt: 'while' expr '{' stmt* '}';

return_stmt:
	'return' expr? ';' ;

expr_stmt: expr ';';

left_value:
  IDENTIFIER
  | left_value '[' expr ']';

// Expressions, in order of precedence.
expr: // not associative
	or_level_expr;

or_level_expr: // left associative
	or_level_expr OR and_level_expr
	| and_level_expr;

and_level_expr: // left associative
	and_level_expr AND cmp_level_expr
	| cmp_level_expr;

cmp_level_expr: // not associative
	add_sub_level_expr CMP_OPERATOR add_sub_level_expr
	| add_sub_level_expr;

add_sub_level_expr: // left associative
	add_sub_level_expr '+' mul_div_level_expr
	| add_sub_level_expr '-' mul_div_level_expr
	| mul_div_level_expr;

mul_div_level_expr: // left associative
	mul_div_level_expr '*' if_level_expr
	| mul_div_level_expr '/' if_level_expr
	| mul_div_level_expr '%' if_level_expr
	| if_level_expr;

if_level_expr: get_or_apply_level_expr | if_expr;
if_expr: 'if' expr block_expr ('else' (if_expr | block_expr))?;

get_or_apply_level_expr:
	value_expr # value_expr_
	// x[y]
	| get_or_apply_level_expr '[' expr ']' # get_expr_
	// f(x, y)
	| get_or_apply_level_expr '(' (expr (',' expr)*)? ')' # apply_expr;

// Value expressions
value_expr:
	unit_expr
	| group_expr
	| tuple_expr
	| array_expr
	| bool_expr
	| identifier_expr
	| block_expr
	| neg_expr
	| floating_point_expr
	| int_expr
	| not_expr
	| array_make_expr;
unit_expr: '(' ')'; // ()
group_expr: '(' expr ')'; // (x)
tuple_expr:
	'(' expr (',' expr)+ ')'; // (x, y); 1-tuple is not allowed
array_expr:
	'[' expr (',' expr)* ']'; // [x, y, z]
block_expr: '{' stmt* expr? '}'; // { blah; blah; }
bool_expr: 'true' | 'false';
neg_expr: '-' value_expr;
floating_point_expr: NUMBER '.' NUMBER?; // 1.0 | 1.
int_expr: NUMBER; // 1
not_expr: '!' expr ; // !x
array_make_expr:
	ARRAY '::' 'make' '(' expr ',' expr ')'; // Array::make(x, y)
identifier_expr: IDENTIFIER;

// Types
type:
	'Unit'
	| 'Bool'
	| 'Int'
	| 'Double'
	| array_type
	| tuple_type
	| function_type;
array_type: 'Array' '[' type ']';
tuple_type: '(' type (',' type)* ')'; // (Int, Bool)
function_type:
	'(' type (',' type)* ')' '->' type; // (Int, Bool) -> Int

// Tokens

TRUE: 'true';
FALSE: 'false';
UNIT: 'Unit';
BOOL: 'Bool';
INT: 'Int';
DOUBLE: 'Double';
ARRAY: 'Array';
NOT: 'not';
IF: 'if';
ELSE: 'else';
FN: 'fn';
LET: 'let';
NUMBER: [0-9]+;
IDENTIFIER: [a-zA-Z_][a-zA-Z0-9_]*;
CMP_OPERATOR: '==' | '!=' | '>=' | '<=' | '<' | '>';
AND: '&&';
OR: '||';
DOT: '.';
ADD: '+';
SUB: '-';
MUL: '*';
DIV: '/';
ASSIGN: '=';
LPAREN: '(';
RPAREN: ')';
LBRACKET: '[';
RBRACKET: ']';
LCURLYBRACKET: '{';
RCURLYBRACKET: '}';
ARROW: '->';
COLON: ':';
SEMICOLON: ';';
COMMA: ',';
WS: [ \t\r\n]+ -> skip;
COMMENT: '//' ~[\r\n]* -> skip;
