enum List[T] {
  Nil;
  Cons(T, List[T]);
}

enum Option[T] {
  None;
  Some(T);
}

enum CompareResult {
  Less;
  Equal;
  Greater;
}

fn[T] unwrap_or(opt: Option[T], default_v: (Unit) -> T) -> T {
  match opt {
    None => default_v(());
    Some(value) => value;
  }
}

fn[T] new_list() -> List[T] {
  Nil
}

fn[T] push(list: List[T], value: T) -> List[T] {
  match list {
    Nil => Cons(value, Nil);
    Cons(head, tail) => Cons(head, push(tail, value));
  }
}

fn[T] append(list1: List[T], list2: List[T]) -> List[T] {
  match list1 {
    Nil => list2;
    Cons(head, tail) => Cons(head, append(tail, list2));
  }
}

fn[T] max_element(list: List[T], compare: (T, T) -> CompareResult) -> Option[T] {
  match list {
    Nil => None;
    Cons(head, tail) => {
      match max_element(tail, compare) {
        None => { Some(head) };
        Some(max_tail) => {
          match compare(head, max_tail) {
            Less => Some(max_tail);
            Equal => Some(head);
            Greater => Some(head);
          }
        };
      }
    }
  }
}

fn[T] min_element(list: List[T], compare: (T, T) -> CompareResult) -> Option[T] {
  match list {
    Nil => None;
    Cons(head, tail) => {
      match min_element(tail, compare) {
        None => { Some(head) };
        Some(min_tail) => {
          match compare(head, min_tail) {
            Less => Some(head);
            Equal => Some(head);
            Greater => Some(min_tail);
          }
        };
      }
    }
  }
}

fn[T] first(list: List[T]) -> Option[T] {
  match list {
    Nil => None;
    Cons(head, _) => Some(head);
  }
}

fn[T] last(list: List[T]) -> Option[T] {
  match list {
    Nil => None;
    Cons(head, Nil) => Some(head);
    Cons(_, tail) => last(tail);
  }
}

fn[T] reverse(list: List[T]) -> List[T] {
  fn reverse_helper(list: List[T], acc: List[T]) -> List[T] {
    match list {
      Nil => acc;
      Cons(head, tail) => reverse_helper(tail, Cons(head, acc));
    }
  }
  reverse_helper(list, Nil)
}

fn[T] length(list: List[T]) -> Int {
  match list {
    Nil => 0;
    Cons(_, tail) => 1 + length(tail);
  }
}

fn[T] is_empty(list: List[T]) -> Bool {
  match list {
    Nil => true;
    _ => false;
  }
}

fn[T] contains(list: List[T], value: T, eq: (T, T) -> Bool) -> Bool {
  match list {
    Nil => false;
    Cons(head, tail) => {
      if eq(head, value) {
        true
      } else {
        contains(tail, value, eq)
      }
    }
  }
}

fn[T] index_of(list: List[T], value: T, eq:(T, T) -> Bool) -> Option[Int] {
  fn index_helper(list: List[T], value: T, index: Int) -> Option[Int] {
    match list {
      Nil => None;
      Cons(head, tail) => {
        if eq(head, value) {
          Some(index)
        } else {
          index_helper(tail, value, index + 1)
        }
      }
    }
  }
  index_helper(list, value, 0)
}

fn[T] remove(list: List[T], value: T, eq:(T, T) -> Bool) -> List[T] {
  match list {
    Nil => Nil;
    Cons(head, tail) => {
      if eq(head, value) {
        tail
      } else {
        Cons(head, remove(tail, value, eq))
      }
    }
  }
}

fn bool_to_int(b: Bool) -> Int {
  match b {
    true => 1;
    false => 0;
  }
}

fn main {
  fn default_int(t: Unit) -> Int {
    0
  }

  fn compare_int(a: Int, b: Int) -> CompareResult {
    if a < b {
      Less
    } else if a == b {
      Equal
    } else {
      Greater
    }
  }

  fn eq_int(a: Int, b: Int) -> Bool {
    a == b
  }
  let mut list = new_list();
  let mut list2 = new_list();
  let r1 = bool_to_int(is_empty(list)); // 1
  list = push(list, 10);
  list = push(list, 20);
  list = push(list, 30);
  list2 = push(list2, 40);
  list2 = push(list2, 50);
  list = append(list, list2);
  let r2 = bool_to_int(is_empty(list)); // 0
  let r3 = unwrap_or(first(list), default_int); // 10
  let r4 = unwrap_or(last(list), default_int); // 50
  let r5 = unwrap_or(max_element(list, compare_int), default_int); // 50
  let r6 = unwrap_or(min_element(list, compare_int), default_int); // 10
  let r7 = length(list); // 5
  let r8 = bool_to_int(contains(list, 30, eq_int)); // 1
  let r9 = bool_to_int(contains(list, 7, eq_int)); // 0
  let r10 = unwrap_or(index_of(list, 20, eq_int), default_int); // 1
  list = reverse(list);
  let r11 = unwrap_or(index_of(list, 20, eq_int), default_int); // 3
  list = remove(list, 20, eq_int);
  let r12 = bool_to_int(contains(list, 20, eq_int)); // 0

  print_int(r1);
  print_int(r2);
  print_int(r3);
  print_int(r4);
  print_int(r5);
  print_int(r6);
  print_int(r7);
  print_int(r8);
  print_int(r9);
  print_int(r10);
  print_int(r11);
  print_int(r12);
}
