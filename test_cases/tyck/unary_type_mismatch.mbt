
fn never_be_zero(n: Int) -> Int {
  if !n {
    n + 1
  } else {
    n
  }
}

fn main {
  let x = never_be_zero(0);
  let y = never_be_zero(1);
  let z = never_be_zero(-1);
  print_int(x);
  print_int(y);
  print_int(z);
}
