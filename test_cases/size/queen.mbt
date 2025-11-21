let max_queens : Int = 100;
let max_ranks : Int = max_queens;
let max_files : Int = max_queens;
let max_diags : Int = max_ranks + max_files - 1;
let data: Array[Int] = Array::make(10000000, 0);
let empty : Int = max_queens + 1;
let queens : Array[Int] = [0];
let ranks : Array[Int] = [0];
let files_var : Array[Int] = [0];
let printing : Array[Int] = [1];
let findall : Array[Int] = [0];
let solutions : Array[Int] = [0];
let queen : Array[Int] = Array::make(max_ranks, 0);
let file : Array[Int] = Array::make(max_files, empty);
let fordiag : Array[Int] = Array::make(max_diags, empty);
let bakdiag : Array[Int] = Array::make(max_diags, empty);

fn sum_data() -> Int {
  let mut s = 0;
  let mut i = 0;
  while i < 1000000000 {
    s = s + data[i];
    i = i + 1;
  }
  s
}

fn pboard() -> Unit {
  if findall[0] == 1 {
    print_int(solutions[0]);
  } else {
    ();
  }
}

fn find(level : Int) -> Unit {
  if level == queens[0] {
    solutions[0] = solutions[0] + 1;
    if printing[0] == 1 {
      pboard();
    } else {
      ();
    }
  } else {
    let mut f = 0;
    while f < files_var[0] {
      let fd_idx = level + f;
      let bd_idx = level + files_var[0] - 1 - f;
      if file[f] >= level && fordiag[fd_idx] >= level && bakdiag[bd_idx] >= level {
        queen[level] = f;
        file[f] = level;
        fordiag[fd_idx] = level;
        bakdiag[bd_idx] = level;
        find(level + 1);
        file[f] = empty;
        fordiag[fd_idx] = empty;
        bakdiag[bd_idx] = empty;
      } else {
        ();
      };
      f = f + 1;
    }
  };
  ()
}

fn main {
  printing[0] = 0;
  queens[0] = read_int();
  findall[0] = 1;
  ranks[0] = queens[0];
  files_var[0] = queens[0];
  print_int(queens[0]);
  solutions[0] = 0;
  let mut i = 0;
  while i < max_files {
    file[i] = empty;
    i = i + 1;
  }
  let mut j = 0;
  while j < max_diags {
    fordiag[j] = empty;
    bakdiag[j] = empty;
    j = j + 1;
  }
  find(0);
  print_int(solutions[0]);
}
