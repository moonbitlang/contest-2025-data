enum Node {
  Number(Int);
  Add(Node, Node);
  Sub(Node, Node);
  Mul(Node, Node);
  Div(Node, Node);
}

fn eval(node: Node) -> Int {
  match node {
    Number(n) => n;
    Add(lhs, rhs) => eval(lhs) + eval(rhs);
    Sub(lhs, rhs) => eval(lhs) - eval(rhs);
    Mul(lhs, rhs) => eval(lhs) * eval(rhs);
    Div(lhs, rhs) => {
      if eval(rhs)== 0 {
        0
      } else {
        eval(lhs) / eval(rhs)
      }
    }
  }
}

enum Token {
  LParen;
  RParen;
  Plus;
  Minus;
  Mult;
  Divi;
  Integer(Int);
}

enum List[T] {
  Nil;
  Cons(T, List[T]);
}

fn[T] len_of_list(list: List[T]) -> Int {
  match list {
    Nil => 0;
    Cons(_, tail) => 1 + len_of_list(tail);
  }
}

fn[T] list_append(list: List[T], item: T) -> List[T] {
  match list {
    Nil => Cons(item, Nil);
    Cons(head, tail) => Cons(head, list_append(tail, item));
  }
}

fn revparse(node: Node, pre: List[Token]) -> List[Token] {
  match node {
    Number(n) => list_append(pre, Integer(n));
    Add(lhs, rhs) => {
      let l = list_append(pre, LParen);
      let l = list_append(l, Plus);
      let l = revparse(lhs, l);
      let l = revparse(rhs, l);
      list_append(l, RParen);
    };
    Sub(lhs, rhs) => {
      let l = list_append(pre, LParen);
      let l = list_append(l, Minus);
      let l = revparse(lhs, l);
      let l = revparse(rhs, l);
      list_append(l, RParen);
    };
    Mul(lhs, rhs) => {
      let l = list_append(pre, LParen);
      let l = list_append(l, Mult);
      let l = revparse(lhs, l);
      let l = revparse(rhs, l);
      list_append(l, RParen);
    };
    Div(lhs, rhs) => {
      let l = list_append(pre, LParen);
      let l = list_append(l, Divi);
      let l = revparse(lhs, l);
      let l = revparse(rhs, l);
      list_append(l, RParen);
    };
  }
}

fn parse(toks: List[Token]) -> (Node, List[Token]) {
  fn skip_rparen(toks: List[Token]) -> List[Token] {
    match toks {
      Cons(RParen, rest) => rest;
      other => other;
    }
  }
  match toks {
    Cons(Integer(n), rest) => (Number(n), rest);
    Cons(Plus, rest) => {
      let (lhs, rest_after_lhs) = parse(rest);
      let (rhs, rest_after_rhs) = parse(rest_after_lhs);
      let rest_after_rhs = skip_rparen(rest_after_rhs);
      (Add(lhs, rhs), rest_after_rhs)
    };
    Cons(Minus, rest) => {
      let (lhs, rest_after_lhs) = parse(rest);
      let (rhs, rest_after_rhs) = parse(rest_after_lhs);
      let rest_after_rhs = skip_rparen(rest_after_rhs);
      (Sub(lhs, rhs), rest_after_rhs)
    };
    Cons(Mult, rest) => {
      let (lhs, rest_after_lhs) = parse(rest);
      let (rhs, rest_after_rhs) = parse(rest_after_lhs);
      let rest_after_rhs = skip_rparen(rest_after_rhs);
      (Mul(lhs, rhs), rest_after_rhs)
    };
    Cons(Divi, rest) => {
      let (lhs, rest_after_lhs) = parse(rest);
      let (rhs, rest_after_rhs) = parse(rest_after_lhs);
      let rest_after_rhs = skip_rparen(rest_after_rhs);
      (Div(lhs, rhs), rest_after_rhs)
    };
    Cons(_, rest) => parse(rest);
    Nil => (Number(-1), Nil);
  }
}

fn random_gen(seed: Int, range:(Int, Int)) -> (Unit) -> Int {
  let mut state = seed;
  fn next_random() {
    let (a, c) = (1664525, 1013904223);
    state = a * state + c;
    state
  }

  fn gen(t:Unit) -> Int {
    let (low, upper) = range;
    let (low, upper) = if low < upper {
      (low, upper)
    } else {
      (upper, low)
    };
    let n = next_random();
    if n < 0 {
      -n % (upper - low) + low
    } else {
      n % (upper - low) + low
    }
  }

  gen
}

fn random_node(gen: (Unit) -> Int, deep: Int) -> Node {

  let op = gen(()) % 4;
  let lhs_n = gen(()) % 100;
  let lhs = if deep > 30 {
    Number(lhs_n)
  } else if lhs_n < 20 {
    Number(lhs_n)
  } else {
    random_node(gen, deep + 1)
  };

  let rhs_n = gen(()) % 100;
  let rhs = if deep > 30 {
    Number(rhs_n)
  } else if rhs_n < 20 {
    Number(rhs_n)
  } else {
    random_node(gen, deep + 1)
  };
  match op {
    0 => Add(lhs, rhs);
    1 => Sub(lhs, rhs);
    2 => Mul(lhs, rhs);
    _ => Div(lhs, rhs);
  }
}

fn main {
  let seed = read_int();
  let gen = random_gen(seed,(0, 51));
  let node = random_node(gen, 0);

  let toks = revparse(node, Nil);
  let (node, _) = parse(toks);
  let result = eval(node);

  print_int(result)
}
