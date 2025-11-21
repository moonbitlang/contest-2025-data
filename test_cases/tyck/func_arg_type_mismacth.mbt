
fn fact(x: Int) -> Int {
  if x <= 1 {
    return 1;
  };

  x * fact(x - 1)
}

fn main {
  let result = fact(3.0);
  print_int(result);
}
