

fn new_array() -> (Array[Double], Int) {
  ([1.0, 2.0, 3.0, 4.0, 5.0], 5)
}

fn main {
  let (sz, arr) : (Int, Array[Double]) = new_array();
  print_int(sz);
}
