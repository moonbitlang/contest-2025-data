fn f(n: Int) -> Int {
  let t : Int = {
    let a = n + 1;
    let b = n - 1;
    print_int(a + b);
  };
  return t;
}

fn main {
  let _ = f(10);
}
