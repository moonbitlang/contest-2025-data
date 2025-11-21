
fn[T] any(arr: Array[T], f: (T) -> Bool, num: Int) -> Bool {
  let mut idx = 0;
  let mut res = false;
  while idx < num {
    res = res || f(arr[idx]);
    idx = idx + 1;
  }
  res
}

fn is_even(x: Int) -> Bool {
  x % 2 == 0
}

fn main {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  if any(arr, is_even, 10) {
    print_int(1)
  } else {
    print_int(0)
  }
}
