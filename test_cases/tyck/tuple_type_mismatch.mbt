
fn swap(t: (Int, Double)) -> (Double, Int) {
  let (x, y) = t;
  (y, x)
}


fn main {
  let (a, b) = swap((3.14, 42));
  print_int(a);
  print_int(int_of_float(b));
}
