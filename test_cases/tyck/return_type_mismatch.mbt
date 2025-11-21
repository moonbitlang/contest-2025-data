
fn f() -> Int {
  42
}

fn g() -> Double {
  3.14
}

fn h(x: Bool) -> Int {
  if !x {
    return f();
  }else {
    return g;
  }
}

fn main {
  let a = h(true);
  let b = h(false);
  print_int(a+b);
}
