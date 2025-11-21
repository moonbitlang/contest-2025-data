

fn foo(n: Int) -> Unit {
  if n {
    print_int(n);
  } else {
    print_int(100);
  }
}

fn main {
  foo(42);
  foo(0);
}
