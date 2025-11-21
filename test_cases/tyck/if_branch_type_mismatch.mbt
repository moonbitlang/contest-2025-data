

fn foo(y: Int) -> Unit {
  let x = (
    if y > 0 {
      133
    } else {
      false
    }
  );
  print_int(x);
}

fn main {
  foo(10);
  foo(-5);
}
