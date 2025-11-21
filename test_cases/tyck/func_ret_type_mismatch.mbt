
fn sum(arr: Array[Double], sz: Int) -> Double {
  let mut total = 0.0;
  let mut i = 0;
  while i < sz {
    total = total + arr[i];
    i = i + 1;
  }
}

fn main {
  let arr = [1.0, 2.0, 3.0, 4.0, 5.0];
  let t = sum(arr, 5);
  print_int(int_of_float(t))
}
