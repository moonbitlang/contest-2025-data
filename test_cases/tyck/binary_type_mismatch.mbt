fn fact(n: Int) -> Int {
  if n <= 1 {
    return 1;
  };

  n * fact(n - 1);
}

fn dfact(n: Double) -> Double {
  if n <= 1.0 {
    return 1.0;
  };

  n * dfact(n - 1.0);
}

fn main {
  if fact(5) == dfact(5.0) {
    print_int(1)
  } else {
    print_int(0)
  }
}
