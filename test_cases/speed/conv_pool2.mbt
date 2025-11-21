fn random_gen(seed: Int, range:(Int, Int)) -> (Unit) -> Int {
  let mut state = seed;
  fn next_random() {
    let (a, c) = (1664525, 1013904223);
    state = a * state + c;
    state
  }

  fn gen(t:Unit) -> Int {
    let (low, upper) = range;
    let (low, upper) = if low < upper {
      (low, upper)
    } else {
      (upper, low)
    };
    next_random() % (upper - low) + low
  }

  gen
}

fn relu(x: Double) -> Double {
  if x >= 0.0 {
    x
  } else {
    0.0
  }
}

fn leaky_relu(x: Double, alpha: Double) -> Double {
  if x >= 0.0 {
    x
  } else {
    alpha * x
  }
}

struct ValArray[T] {
  data: Array[Array[T]];
  w: Int;
  h: Int;
}

fn conv(mat: ValArray[Double], kernel: ValArray[Double], stride: Int, activation: (Double) -> Double) -> ValArray[Double] {
  let (mat, w, h) = (mat.data, mat.w, mat.h);
  let (kernel, kw, kh) = (kernel.data, kernel.w, kernel.h);
  let output_w = (w - kw) / stride + 1;
  let output_h = (h - kh) / stride + 1;
  let output_mat = Array::make(output_h, [0.0]);
  let mut i = 0;
  while i < output_h {
    output_mat[i] = Array::make(output_w, 0.0);
    i = i + 1;
  }

  let mut row = 0;
  let mut col = 0;
  let mut kr = 0;
  let mut kc = 0;

  while col < output_h {
    row = 0;
    while row < output_w {
      kc = 0;
      while kc < kw {
        kr = 0;
        while kr < kh {
          output_mat[col][row] = output_mat[col][row] + mat[col * stride + kr][row * stride + kc] * kernel[kr][kc];
          kr = kr + 1;
        }
        kc = kc + 1;
      }
      output_mat[col][row] = activation(output_mat[col][row]);
      row = row + 1;
    }
    col = col + 1;
  }
  ValArray::{ data: output_mat, w: output_w, h: output_h}
}


fn max_pooling(mat: ValArray[Double], kw: Int, kh: Int, stride: Int) -> ValArray[Double] {
  let (mat, w, h) = (mat.data, mat.w, mat.h);
  let output_w = (w - kw) / stride + 1;
  let output_h = (h - kh) / stride + 1;
  let output_mat = Array::make(output_h, [0.0]);
  let mut i = 0;
  while i < output_h {
    output_mat[i] = Array::make(output_w, 0.0);
    i = i + 1;
  }

  let mut row = 0;
  let mut col = 0;
  let mut kr = 0;
  let mut kc = 0;

  while row < output_h {
    col = 0;
    while col < output_w {
      let mut max_val = -10000000000.0;
      kr = 0;
      while kr < kh {
        kc = 0;
        while kc < kw {
          let row_idx = row * stride + kr;
          let col_idx = col * stride + kc;
          let mut value = 0.0;
          if row_idx < h && col_idx < w {
            value = mat[row * stride + kr][col * stride + kc];
          };
          if value > max_val {
            max_val = value;
          };
          kc = kc + 1;
        }
        kr = kr + 1;
      }
      output_mat[row][col] = max_val;
      col = col + 1;
    }
    row = row + 1;
  }
  ValArray::{ data: output_mat, w: output_w, h: output_h}
}

fn conv_and_pool(mat: ValArray[Double], conv_kernel: ValArray[Double], conv_stride: Int, pool_ksize: (Int, Int), pool_stride: Int, activation: (Double) -> Double) -> ValArray[Double] {
  let conv_out = conv(mat, conv_kernel, conv_stride, activation);
  let (pool_kw, pool_kh) = pool_ksize;
  let pool_out = max_pooling(conv_out, pool_kw, pool_kh, pool_stride);
  pool_out
}

fn print_mat(mat: ValArray[Double]) -> Unit {
  let (mat, w, h) = (mat.data, mat.w, mat.h);
  let mut i = 0;
  let mut j = 0;
  while i < h {
    j = 0;
    while j < w {
      print_int(truncate(mat[i][j]));
      j = j + 1;
    }
    i = i + 1;
  }
}

fn main {
  let seed : Int = read_int();
  let data_w : Int = 4096;
  let data_h : Int = 2048;
  let gen = random_gen(seed, (0, 100));
  let data = Array::make(data_h, [0.0]);
  let mut ih = 0;
  while ih < data_h {
    data[ih] = Array::make(data_w, 0.0);
    let mut iw = 0;
    while iw < data_w {
      data[ih][iw] = float_of_int(gen(()));
      iw = iw + 1;
    }
    ih = ih + 1;
  }

  let data = ValArray::{ data: data, w: data_w, h: data_h};
  
  let conv_kernel = [
    [0.5, 0.25, -0.15],
    [0.7, -0.1, 0.2],
    [-0.2, 0.6, 0.2]
  ];
  fn leaky_relu1(x) {
    leaky_relu(x, 0.01)
  }

  fn leaky_relu2(x) {
    leaky_relu(x, 0.05)
  }

  fn leaky_relu3(x) {
    leaky_relu(x, 0.08)
  }
  let conv_kernel = ValArray::{ data: conv_kernel, w: 3, h: 3};
  let pool_ksize = (2, 2);
  let pool_stride = 2;
  let out = conv_and_pool(data, conv_kernel, 1, pool_ksize, pool_stride, relu);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, leaky_relu1);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, relu);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, leaky_relu2);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, relu);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, leaky_relu3);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, relu);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, leaky_relu1);
  let out = conv_and_pool(out, conv_kernel, 1, pool_ksize, pool_stride, relu);
  print_mat(out);
}
