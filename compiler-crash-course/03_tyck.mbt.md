# 类型检查

在有一个抽象语法树之后，我们需要进行的下一步是为语法树的各个部分标上类型。

其实类型标注这个事情并不必须在做完语法分析之后进行；
只要你能写出来，你完全可以把类型检查安排在更早或者更晚的地方
（例如，很多动态类型语言会推迟到运行时再做类型检查）。
不过，在得到抽象语法树之后先做类型检查是在静态编译的过程中比较常见的做法。

> 为了简单起见，我们在这里将不会涉及太多类型系统的知识。
> 如果你对严谨地定义一个类型系统有兴趣（或者只是单纯的想画平衡木），
> 可以参阅类型系统的教材，例如 [Types and Programming Languages (TAPL)][tapl]、
> [Practical Foundations for Programming Languages (PFPL)][pfpl]、
> [Programming Languages Foundations in Agda (PLFA)][plfa] 等等。
>
> 观前提示：类型系统包含的知识非常多，而且很多内容比较抽象，
> 在决定深入学习之前请三思（笑）。

[tapl]: https://www.cis.upenn.edu/~bcpierce/tapl/
[pfpl]: https://www.cs.cmu.edu/~rwh/pfpl/abbrev.pdf
[plfa]: https://plfa.github.io/

## 类型定义、带类型的抽象语法树（Typed AST/TAST）

在我们用作示例的超级简化版 MiniMoonBit 中，我们只会用到两种类型：

- 整数类型 `Int`
- 函数类型，我们写作 `fn(A) -> B`。

让我们先定义一下这两个类型：

```mbt
enum Ty {
  Int
  Fn(Array[Ty], Ty)
  /// 表示一个未知的类型变量
  TVar(Ref[Ty?])
} derive(Show)
```

其中，`TVar` 表示目前还未知的类型。你可以在下一节中看到它的用法。

<details>
<summary>折叠的是先前抽象语法树的定义</summary>

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
  return_type : AstType
  body : Expression
} derive(Show)

/// 代表一个参数
struct Param {
  name : String
  ty : AstType
} derive(Show)

/// 类型定义，为了简单我们就先用字符串代替吧
struct AstType {
  name : String
} derive(Show)

/// 表达式定义，可能有很多种，所以我们用一个 enum 表示
enum Expression {
  /// 定义变量
  Let(name~ : String, ty~ : AstType?, value~ : Expression, body~ : Expression)
  /// 变量
  Variable(name~ : String)
  /// 整数常量
  IntLiteral(value~ : Int)
  /// 加法表达式
  Add(left~ : Expression, right~ : Expression)
  /// 函数调用
  Call(func~ : Expression, args~ : Array[Expression])
} derive(Show)

```

</details>

相比我们上一章使用的抽象语法树，
我们添加了一个新的表达式类型 `Let` 用于创建变量，以便演示关于变量定义的类型检查。
它的语义相当于 `let <name> : <ty> = <value>; <body>`。

```
  Let(name~ : String, ty~ : AstType?, value~ : Expression, body~ : Expression)
```

我们需要为抽象语法树的每一个节点标注它们的类型：

```mbt
struct TProgram {
  top_levels : Map[String,TTopLevel]
} derive(Show)

enum TTopLevel {
  Function(func~ : TFunction)
} derive(Show)

struct TFunction {
  name : String
  params : Array[TParam]
  return_type : Ty
  body : TExpression
} derive(Show)

struct TParam {
  name : String
  ty : Ty
} derive(Show)

struct TExpression {
  expr : TExprKind
  ty : Ty
} derive(Show)

enum TExprKind {
  Let(name~ : String, ty~ : Ty, value~ : TExpression, body~ : TExpression)
  Variable(name~ : String)
  IntLiteral(value~ : Int)
  Add(left~ : TExpression, right~ : TExpression)
  Call(func~ : TExpression, args~ : Array[TExpression])
} derive(Show)
```

## Unification（归一化）

我们在这里将使用的算法是 Unification（归一化）。
这是一个应用很广泛的推导算法，其核心思想大概[可以如此概括][unif_notes]：

1. 对于所有不知道类型的东西，给它定义一个类型变量；
2. 对于所有需要满足的类型约束，把现有的未知的类型尽可能少地特化，以满足这个约束。
   如果满足不了，就报错。

[unif_notes]: https://langdev.stackexchange.com/a/3018

放到我们的场景中，可以如此理解：

- 对于一个不知道类型的东西，比如一个新的变量 `let x`，
  我们可以先给他一个类型变量 `T` 表示 `x` 的类型是未知的；
- 一个表达式的类型可能从两个方向获得：
  - 一方面是外部期望，例如 `let a: Int = x` 中，`x` 被期望获得 `Int` 类型；
  - 另一方面是表达式本身的结构，例如数字字面量 `10` 的类型必然是 `Int`。
- 归一化算法会尝试尽可能少地修改这两个约束，使两者达成一致。
  如果无法达成一致，就报错。

```mbt
suberror TyErr {
  UnificationFailed(String, Ty, Ty)
  UnknownType(AstType)
  UnknownVar(String)
  FuncArgCountMismatch(Int, Int)
  UnresolvedTyVar
  OccursCheckFailed(Ty, Ty)
} derive(Show)
```

## 全局的类型推导

由于 MiniMoonBit 强制所有顶级函数都必须显式地标注类型，
我们可以在不处理函数体的情况下先为所有顶级函数标注类型。

我们先定义一下变量作用域：

```mbt
typealias @immut/sorted_map.SortedMap[String, Ty] as Scope
```

然后我们就可以为所有顶级函数标注类型了：

```mbt
fn resolve_type(ast_ty: AstType) -> Ty raise TyErr {
  match ast_ty.name {
    "Int" => Int
    _ => raise UnknownType(ast_ty)
  }
}

/// 为整个程序进行类型检查
fn type_program(prog : Program) -> TProgram raise TyErr {
  // 全局作用域
  let mut global = Scope::new()
  let new_toplevels = {}
  for tl in prog.top_levels {
    match tl {
      Function(func~) => {
        // 解析函数参数的类型
        let param_ty = []
        let mut function_scope = global
        for p in func.params {
          let resolved = resolve_type(p.ty)
          param_ty.push(resolved)
          function_scope = function_scope.add(p.name, resolved)
        }
        // 解析函数返回值的类型
        let ret_ty = resolve_type(func.return_type)

        // 把函数定义加入到全局作用域和当前函数作用域
        let func_ty = Fn(param_ty, ret_ty)
        global = global.add(func.name, func_ty)
        function_scope = function_scope.add(func.name, func_ty)

        // 解析函数体的类型，后面会实现
        let typed_body = type_expr(func.body, function_scope)

        // 插入类型检查过的函数
        new_toplevels.set(
          func.name,
          TTopLevel::Function(func={
            name: func.name,
            params: func.params.map(p => {
              name: p.name,
              ty: resolve_type(p.ty),
            }),
            return_type: ret_ty,
            body: typed_body,
          }),
        )
      }
    }
  }
  return { top_levels: new_toplevels }
}
```

## 为表达式推导类型

下面我们就该在局部变量和表达式上实现之前提到的归一化算法了。

先写一下简单的、不需要归一的情况：

```mbt
fn type_expr(expr : Expression, scope : Scope) -> TExpression raise TyErr {
  match expr {
    // 整数常量的类型就是整数
    IntLiteral(value~) => { ty: Int, expr: TExprKind::IntLiteral(value~) }
    // 变量的类型从作用域中查找
    Variable(name~) =>
      match scope.get(name) {
        Some(ty) => { ty, expr: TExprKind::Variable(name~) }
        None => raise UnknownVar(name)
      }
    // 待实现
    Let(name~, ty~, value~, body~) => type_let(name, ty, value, body, scope)
    Add(left~, right~) => type_add(left, right, scope)
    Call(func~, args~) => type_call(func, args, scope)
  }
}
```

然后我们先看加法：它要求两侧的表达式的类型都是整数。
为了清楚起见，我们把这个约束拆成两步：

1. 两边表达式类型一致；
2. 这个一致的类型是整数。

我们通过后面会实现的 `unify` 函数来实现这个过程，先实现 `add` 本体：

```mbt
///|
fn type_add(
  left : Expression,
  right : Expression,
  scope : Scope,
) -> TExpression raise TyErr {
  let type_left = type_expr(left, scope)
  let type_right = type_expr(right, scope)
  // 先让两边的类型一致
  unify(type_left.ty, type_right.ty, "making both sides of `+` the same type")
  // 再让这个类型是整数
  unify(type_left.ty, Int, "making the type of `+` be Int")
  return { expr: Add(left=type_left, right=type_right), ty: type_left.ty }
}
```

一个更复杂的实现可能会同时允许整数和整数相加，以及浮点数和浮点数相加。
这个时候，第二个 `unify` 可能就需要被替换成一个 “判断得到的类型是否可以相加” 的函数了。

类似地，我们可以实现 `call` 的类型检查。
这个时候，我们需要用到 `unify` 检查。

```mbt
///|
fn type_call(
  func : Expression,
  args : Array[Expression],
  scope : Scope,
) -> TExpression raise TyErr {
  // 到现在为止我们还不知道函数的返回值类型，我们给它起一个名字
  let ret_ty = TVar(Ref::new(None))

  // 我们对函数和参数本身进行类型检查
  let typed_func = type_expr(func, scope)
  let result_args = []
  for arg in args {
    let typed_arg = type_expr(arg, scope)
    result_args.push(typed_arg)
  }

  // 现在我们断言，我们目前拥有的参数和返回值类型组成的函数类型应当和被调用的函数相同。
  //
  // 对于这个简单的示例，这一步看起来可能比较多余，但是当目标函数是泛型函数时
  // 我们可以一步确定所有需要确定的泛型类型。
  let expected_type = Fn(result_args.map(a => a.ty), ret_ty)
  unify(typed_func.ty, expected_type, "matching function type")

  // 在归一化之后，我们可以直接返回这个结果类型
  return { expr: Call(func=typed_func, args=result_args), ty: ret_ty }
}
```

`let` 的实现方式和上面的类似，只需要把计算表达式得到的类型和变量声明的类型归一化就行了：

```mbt
fn type_let(
  name : String,
  ast_ty : AstType?,
  value : Expression,
  body : Expression,
  scope : Scope,
) -> TExpression raise TyErr {
  // 计算值的类型
  let typed_value = type_expr(value, scope)

  // 如果声明了类型，就把它和计算出来的类型归一化
  if ast_ty is Some(ty) {
    let declared_ty = resolve_type(ty)
    unify(typed_value.ty, declared_ty, "matching let binding type")
  }

  // 在新的作用域中计算 body 的类型
  let new_scope = scope.add(name, typed_value.ty)
  let typed_body = type_expr(body, new_scope)

  return { expr: Let(name=name, ty=typed_value.ty, value=typed_value, body=typed_body), ty: typed_body.ty }
}
```

## 实现归一化

到现在为止，我们都只是在使用归一化算法。下面，我们就来分步骤实现它。

```mbt
///|
fn unify(x : Ty, y : Ty, context : String) -> Unit raise TyErr {
  match (x, y) {
    // 对于简单类型，我们只需要判断它们是否相同
    (Int, Int) => ()

    // 函数是个复合类型，我们要对两侧的参数和返回值分别归一化
    (Fn(args1, ret1), Fn(args2, ret2)) => {
      // 先确定参数列表长度
      if args1.length() != args2.length() {
        raise FuncArgCountMismatch(args1.length(), args2.length())
      }
      // 再分别归一化
      for i = 0; i < args1.length(); i = i + 1 {
        unify(args1[i], args2[i], "matching function argument type")
      }
      unify(ret1, ret2, "matching function return type")
    }

    // 至少一方是类型变量
    (TVar(_), _) | (_, TVar(_)) => unify_vars(x, y, context)

    // 否则，报错
    _ => raise UnificationFailed(context, x, y)
  }
}
```

下面只剩下至少一方类型未知的情况还没有实现了。

这里很适合提一下为什么在类型未知的情况下，对应的定义是 `TVar(Ref[Ty?])`。

在 MoonBit 中，`Ref[T]` 是一个可以被多个使用者共享的可变值。
创建时间不同的 `Ref` 对应不同的内存空间，而同一个 `Ref` 可以被多次复制，指向同一片内存。
这样，我们就可以在不改变各处用到的值的情况下细化 `Ref` 包含的类型，
也就是在归一化定义中提到的 “尽可能少地特化以满足约束”。

什么样是尽可能少的特化呢？在我们的例子里，需要做的事情很简单：

1. 如果是复合类型，比如函数，我们只会考虑特化它的每一部分（参数和返回值等等）。
   这个就是上面 `unify` 函数中对函数类型的处理。
2. 如果一方知道类型，而另一方不知道，那么我们就把已知的一方的类型赋值给未知的一方。
3. 如果两方都知道类型，就按照前面的 `unify` 的处理方式去处理它们内部的类型。
   注意到这里有一种情况是两方是同一个类型变量，因为同一个类型变量的内容也是一样的，所以我们不需要特殊处理。
4. 我们永远不会直接修改一个已经知道类型的类型变量的类型。

```mbt
/// 将类型变量解析到最深的已知类型的位置。
///
/// 注意到，这个时候如果还存在类型变量的话，他一定是类型未知的（i.e. `TVar({val: None})`）
fn deref_tvar(ty: Ty) -> Ty {
  match ty {
    TVar(r) => match r.val {
      Some(t) => deref_tvar(t)
      None => ty
    }
    _ => ty
  }
}

/// occurs-check: detect whether target TVar occurs inside ty
fn occurs_in(needle: Ref[Ty?], ty: Ty) -> Bool {
  match deref_tvar(ty) {
    TVar(r2) => physical_equal(needle, r2)
    Fn(args, ret) => {
      for a in args {
        if occurs_in(needle, a) { return true }
      }
      occurs_in(needle, ret)
    }
    _ => false
  }
}

fn unify_vars(x : Ty, y : Ty, context: String) -> Unit raise TyErr {
  // 将两边的类型变量解析到最深的已知类型的位置
  let x_de = deref_tvar(x)
  let y_de = deref_tvar(y)

  // 按照上面的规则进行处理
  match (x_de, y_de) {
    // 都是类型变量：将两者链接到同一个新的类型变量
    (TVar(r1), TVar(r2)) => {
      let new_unified = Ref::new(None)
      r1.val = Some(TVar(new_unified))
      r2.val = Some(TVar(new_unified))
    }
    // 一方是类型变量，另一方是已知或复合类型：进行 occurs-check 后再赋值
    (TVar(r), ty) | (ty, TVar(r)) => {
      if occurs_in(r, ty) {
        raise OccursCheckFailed(TVar(r), ty)
      }
      r.val = Some(ty)
    }
    // 两方都变成了已知类型
    (ty1, ty2) => unify(ty1, ty2, context)
  }
}
```

> 注：为什么需要 occurs-check（出现性检查）：
> 如果把某个类型变量赋值为一个包含其自身的类型（例如 `T = Fn([T], Int)`），
> 就会形成“无限类型”。
> 这会让解引用、打印以及后端阶段在类型上无限展开或循环，直接把编译流程搞崩。
> occurs-check 在将 TVar 绑定为某个类型之前，检查该 TVar 是否出现在该类型中，
> 从源头阻止这类自引用的产生。

## 最后一步

到现在为止，我们已经实现了类型检查的所有功能，
但是我们的 TAST 中还存在一些已经被求值过的类型变量。
为了之后处理的方便，我们最后将 TAST 里面所有类型变量都求值为最终的类型：

```mbt
fn deref_program(tprog: TProgram) -> TProgram raise TyErr {
  let new_toplevels = {}
  for name,tl in tprog.top_levels {
    match tl {
      Function(func~) => {
        let new_body = deref_expr(func.body)
        new_toplevels.set(name, TTopLevel::Function(func={
          name: func.name,
          params: func.params,
          return_type: deref_ty(func.return_type),
          body: new_body,
        }))
      }
    }
  }
  return { top_levels: new_toplevels }
}

fn deref_ty(ty: Ty) -> Ty raise TyErr {
  match deref_tvar(ty) {
    TVar(_) => raise UnresolvedTyVar
    Fn(args, ret) => Fn(args.map(deref_ty), deref_ty(ret))
    other => other
  }
}

fn deref_expr(expr : TExpression) -> TExpression raise TyErr {
  match expr.expr {
    Let(name~, ty~, value~, body~) => {
      let new_value = deref_expr(value)
      let new_body = deref_expr(body)
      {
        expr: Let(name~, ty=deref_ty(ty), value=new_value, body=new_body),
        ty: deref_ty(expr.ty),
      }
    }
    Variable(name~) => { expr: Variable(name~), ty: deref_ty(expr.ty) }
    IntLiteral(value~) => { expr: IntLiteral(value~), ty: deref_ty(expr.ty) }
    Add(left~, right~) => {
      let new_left = deref_expr(left)
      let new_right = deref_expr(right)
      { expr: Add(left=new_left, right=new_right), ty: deref_ty(expr.ty) }
    }
    Call(func~, args~) => {
      let new_func = deref_expr(func)
      let new_args = args.map(deref_expr)
      { expr: Call(func=new_func, args=new_args), ty: deref_ty(expr.ty) }
    }
  }
}
```

把剩下的部分组合一下

```mbt
fn ast_to_tast(prog: Program) -> TProgram raise TyErr {
  let tprog = type_program(prog)
  return deref_program(tprog)
}
```

## 测试

```mbt
test {
  // fn add_one(x: Int) -> Int { x + 1 }
  let prog = Program::{
    top_levels: [
      Function(func={
        name: "add_one",
        params: [
          { name: "x", ty: { name: "Int" } }
        ],
        return_type: { name: "Int" },
        body: Add(
          left=Variable(name="x"),
          right=IntLiteral(value=1)
        )
      })
    ]
  }

  let tast = ast_to_tast(prog)
  inspect(tast, content=(
    #|{top_levels: {"add_one": Function(func={name: "add_one", params: [{name: "x", ty: Int}], return_type: Int, body: {expr: Add(left={expr: Variable(name="x"), ty: Int}, right={expr: IntLiteral(value=1), ty: Int}), ty: Int}})}}
  ))
}

///|
test {
  // fn recursive(x: Int) -> Int { let y = x + 1; recursive(y) }
  let prog = Program::{
    top_levels: [
      Function(func={
        name: "recursive",
        params: [{ name: "x", ty: { name: "Int" } }],
        return_type: { name: "Int" },
        body: Let(
          name="y",
          ty=None,
          value=Add(left=Variable(name="x"), right=IntLiteral(value=1)),
          body=Call(func=Variable(name="recursive"), args=[Variable(name="y")]),
        ),
      }),
    ],
  }
  let tast = ast_to_tast(prog)
  inspect(tast, content=(
    #|{top_levels: {"recursive": Function(func={name: "recursive", params: [{name: "x", ty: Int}], return_type: Int, body: {expr: Let(name="y", ty=Int, value={expr: Add(left={expr: Variable(name="x"), ty: Int}, right={expr: IntLiteral(value=1), ty: Int}), ty: Int}, body={expr: Call(func={expr: Variable(name="recursive"), ty: Fn([Int], Int)}, args=[{expr: Variable(name="y"), ty: Int}]), ty: Int}), ty: Int}})}}
  ))
}
```
