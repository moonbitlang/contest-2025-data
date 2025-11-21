fn[T] bubble_sort(arr: Array[T], len: Int, compare: (T, T) -> Int) -> Array[T] {
  fn bubble_sort_helper(arr: Array[T], len: Int, swapped: Bool, compare: (T, T) -> Int) -> Array[T] {
    if len <= 1 || !swapped {
      return arr;
    };
    
    let mut new_swapped = false;
    let mut i = 0;
    while i < (len - 1) {
      if compare(arr[i], arr[i + 1]) == 1 {
        let temp = arr[i];
        arr[i] = arr[i + 1];
        arr[i + 1] = temp;
        new_swapped = true;
      };
      i = i + 1;
    }
    
    bubble_sort_helper(arr, len - 1, new_swapped, compare);
  }
  
  bubble_sort_helper(arr, len, true, compare);
}

fn main {
  fn compare_int(a: Int, b: Int) -> Int {
    if a < b {
      -1
    } else if a == b {
      0
    } else {
      1
    }
  }

  let arr = [64, 34, 25, 12, 90, 11, 22];
  let len = 7;
  
  let sorted_arr = bubble_sort(arr, len, compare_int);
  
  print_int(sorted_arr[0]);
  print_int(sorted_arr[len-1]);
}
