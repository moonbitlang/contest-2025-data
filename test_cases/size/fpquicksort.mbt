enum List[T] {
  Nil;
  Cons(T, List[T]);
}

fn[T] first(list: List[T], defaultf: (Unit) -> T) -> T {
  match list {
    Nil => defaultf(());
    Cons(head, _) => head;
  }
}

fn[T] last(list: List[T], defaultf: (Unit) -> T) -> T {
  match list {
    Nil => defaultf(());
    Cons(head, Nil) => head;
    Cons(_, tail) => last(tail, defaultf);
  }
}

fn[T] print_list(list: List[T], printFn: (T) -> Unit) -> Unit {
  match list {
    Nil => ();
    Cons(head, tail) => {
      printFn(head);
      print_list(tail, printFn);
    }
  }
}

fn[T] push(list: List[T], element: T) -> List[T] {
  match list {
    Nil => Cons(element, Nil);
    Cons(head, tail) => Cons(head, push(tail, element));
  }
}

fn[T] append(list1: List[T], list2: List[T]) -> List[T] {
  match list1 {
    Nil => list2;
    Cons(head, tail) => Cons(head, append(tail, list2));
  }
}

enum CompareResult {
  Less;
  Equal;
  Greater;
}

fn[T] less(pivot: T, elements: List[T], compare: (T, T) -> CompareResult) -> List[T] {
  match elements {
    Nil => Nil;
    Cons(head, tail) => {
      match compare(head, pivot) {
        Less => Cons(head, less(pivot, tail, compare));
        Equal => Cons(head, less(pivot, tail, compare));
        Greater => less(pivot, tail, compare);
      }
    }
  }
}

fn[T] greater(pivot: T, elements: List[T], compare: (T, T) -> CompareResult) -> List[T] {
  match elements {
    Nil => Nil;
    Cons(head, tail) => {
      match compare(head, pivot) {
        Less => greater(pivot, tail, compare);
        Equal => greater(pivot, tail, compare);
        Greater => Cons(head, greater(pivot, tail, compare));
      }
    }
  }
}

fn[T] quicksort(elements: List[T], compare: (T, T) -> CompareResult) -> List[T] {
  match elements {
    Nil => Nil;
    Cons(head, tail) => {
      let lessList = less(head, tail, compare);
      let greaterList = greater(head, tail, compare);
      let sortedLess = quicksort(lessList, compare);
      let sortedGreater = quicksort(greaterList, compare);
      append(sortedLess, Cons(head, sortedGreater))
    }
  }
}

struct Number[T] {
  v: T;
}

fn main {
  let mut list = Nil;

  fn inner_push(cnt) {
    if cnt <= 0 {
      return;
    };
    list = push(list, Number::{ v : cnt } );
    inner_push(cnt - 1);
  } 

  inner_push(read_int());

  fn compare(a: Number[Int], b: Number[Int]) -> CompareResult {
    if a.v < b.v {
      Less
    } else if a.v > b.v {
      Greater
    } else {
      Equal
    }
  }

  let sorted = quicksort(list, compare);
  fn ret0(t:Unit) -> Number[Int] {
    Number::{ v : 0 }
  }
  let fst = first(sorted, ret0);
  let lst = last(sorted,ret0);
  print_int((fst.v + lst.v) / 2)
}
