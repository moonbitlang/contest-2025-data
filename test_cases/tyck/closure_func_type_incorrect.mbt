

fn main {
  fn max(a, b) {
    if a > b {
      a
    } else {
      b
    }
  }

  print_int(max(5, 10));
  print_int(max(5.0, 10.0));
}
