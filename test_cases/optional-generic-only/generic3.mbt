
fn[T] fold(arr: Array[T], len: Int, f: (T, T) -> T, initial: T) -> T {
  let mut idx = 0;
  let mut result = initial;
  while idx < len {
    result = f(result, arr[idx]);
    idx = idx + 1;
  }
  result
}

fn main {
  let arr1 : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  fn add(x: Int, y) -> Int {
    x + y
  }
  let sum = fold(arr1, 10, add, 0);

  let arr2 : Array[Double] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
  fn fadd(x, y: Double) -> Double {
    x + y
  }
  let dsum = fold(arr2, 10, fadd, 0.0);

  let arr3 : Array[Unit] = Array::make(10, ());
  fn cnt(x, y) -> Unit {
    ()
  }
  let _ = fold(arr3, 10, cnt, ());
  
  print_int(sum + int_of_float(dsum));
}
