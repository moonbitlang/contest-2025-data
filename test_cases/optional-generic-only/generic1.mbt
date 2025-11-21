
fn[T] each(arr: Array[T], f: (T) -> Unit, num: Int) -> Unit {
  let mut idx = 0;
  while idx < num {
    f(arr[idx]);
    idx = idx + 1;
  }
}

fn main {
  let arr = [1, 2, 3, 4, 5];
  each(arr, print_int, 5);
}
