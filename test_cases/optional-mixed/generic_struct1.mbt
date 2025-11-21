struct ValArray[T] {
  vals: Array[Array[T]];
  len: Array[Int];
  cap: Array[Int];
  push: (ValArray[T], T) -> Unit;
  each: (ValArray[T], (T) -> Unit) -> Unit;
  map: (ValArray[T], (T) -> T) -> ValArray[T];
  fold: (ValArray[T], (T, T) -> T, T) -> T;
}

fn[T] new_valarray(cap: Int, default_v: (Unit) -> T) -> ValArray[T] {
  fn push(self: ValArray[T], val: T) -> Unit {
    if self.len[0] < self.cap[0] {
      self.vals[0][self.len[0]] = val;
      self.len[0] = self.len[0] + 1;
    } else {
      self.cap[0] = self.cap[0] * 2;
      let new_vals = Array::make(self.cap[0], default_v(()));
      let mut i = 0;
      while i < self.len[0] {
        new_vals[i] = self.vals[0][i];
        i = i + 1;
      }
      new_vals[self.len[0]] = val;
      self.vals[0] = new_vals;
      self.len[0] = self.len[0] + 1;
    }
  }

  fn each(self: ValArray[T], f: (T) -> Unit) -> Unit {
    let mut i = 0;
    while i < self.len[0] {
      f(self.vals[0][i]);
      i = i + 1;
    }
  }

  fn fold(self: ValArray[T], f: (T, T) -> T, init: T) -> T {
    let mut acc = init;
    let mut i = 0;
    while i < self.len[0] {
      acc = f(acc, self.vals[0][i]);
      i = i + 1;
    }
    acc
  }

  fn map(self: ValArray[T], f: (T) -> T) -> ValArray[T] {
    let new_vals = Array::make(self.len[0], default_v(()));
    let mut i = 0;
    while i < self.len[0] {
      new_vals[i] = f(self.vals[0][i]);
      i = i + 1;
    }
    ValArray::{
      vals: Array::make(1, new_vals),
      len: Array::make(1, self.len[0]),
      cap: Array::make(1, self.cap[0]),
      push: push,
      each: each,
      map: map,
      fold: fold
    }
  }

  let vals = Array::make(1, Array::make(cap, default_v(())));
  let len = Array::make(1, 0);
  let cap = Array::make(1, cap);
  ValArray::{
    vals: vals,
    len: len,
    cap: cap,
    push: push,
    each: each,
    map: map,
    fold: fold
  }
}

fn main {
  fn default_int(t: Unit) -> Int {
    0
  }
  let vals = new_valarray(3, default_int);
  (vals.push)(vals, 1);
  (vals.push)(vals, 2);
  (vals.push)(vals, 3);
  (vals.push)(vals, 4);
  (vals.push)(vals, 5);

  fn double(x: Int) -> Int {
    x * 2
  }

  let doubled_vals = (vals.map)(vals, double);

  fn sum(acc: Int, x: Int) -> Int {
    acc + x
  }

  let total = (doubled_vals.fold)(doubled_vals, sum, 0);
  (doubled_vals.each)(doubled_vals, print_int);
  print_int(total)
}
