let hashmap_length = 1000;
let hashmap_bucket_size = 500;

fn[K] new_hashmap(default_k: (Unit) -> K, default_v: (Unit) -> Double) -> Array[(Array[(K, Double)], Array[Int])] {
  Array::make(hashmap_length, (Array::make(hashmap_bucket_size, (default_k(()), default_v(()))), Array::make(1, 0)));
}

fn[K] hashmap_get(map: Array[(Array[(K, Double)], Array[Int])], key: K, hashf: (K) -> Int, eq: (K, K) -> Int, default_v: Double) -> Double {
  let hash = hashf(key) % hashmap_length;
  let (bucket, bucket_len) = map[hash];
  
  let mut i = 0;
  while i < bucket_len[0] {
    let (stored_key, stored_value) = bucket[i];
    if eq(stored_key, key) == 0 {
      return stored_value;
    };
    i = i + 1;
  }

  default_v
}

fn[K] hashmap_set(map: Array[(Array[(K, Double)], Array[Int])], key: K, value: Double, hashf: (K) -> Int, eq: (K, K) -> Int) -> Unit {
  let hash = hashf(key) % hashmap_length;
  let (bucket, bucket_len) = map[hash];

  let mut i = 0;
  while i < bucket_len[0] {
    let (stored_key, _) = bucket[i];
    if eq(stored_key, key) == 0 {
      bucket[i] = (key, value);
      return ();
    };
    i = i + 1;
  }

  if bucket_len[0] < hashmap_bucket_size {
    bucket[bucket_len[0]] = (key, value);
    bucket_len[0] = bucket_len[0] + 1;
  }
}

fn main {
  fn hash_double(x: Double) -> Int {
    let result = int_of_float(x * 10.0);
    if result < 0 { -result } else { result }
  }

  fn default_double(u: Unit) -> Double {
    0.0 / 0.0
  }

  fn double_eq(a: Double, b: Double) -> Int {
    if a < b {
      -1
    } else if a == b {
      0
    } else {
      1
    }
  }

  let map = new_hashmap(default_double, default_double);
  hashmap_set(map, 1.0, 2.0, hash_double, double_eq);
  hashmap_set(map, 2.0, 4.0, hash_double, double_eq);
  hashmap_set(map, 3.0, 9.0, hash_double, double_eq);
  hashmap_set(map, 4.0, 16.0, hash_double, double_eq);
  hashmap_set(map, 5.0, 25.0, hash_double, double_eq);
  hashmap_set(map, 6.0, 36.0, hash_double, double_eq);
  hashmap_set(map, 7.0, 49.0, hash_double, double_eq);
  hashmap_set(map, 8.0, 64.0, hash_double, double_eq);

  let v1 = hashmap_get(map, 1.0, hash_double, double_eq, 0.0);
  let v2 = hashmap_get(map, 2.5, hash_double, double_eq, 0.0);
  let v3 = hashmap_get(map, 3.0, hash_double, double_eq, 0.0);
  let v4 = hashmap_get(map, 4.5, hash_double, double_eq, 0.0);
  let v5 = hashmap_get(map, 5.0, hash_double, double_eq, 0.0);
  let v6 = hashmap_get(map, 6.0, hash_double, double_eq, 0.0);
  let v7 = hashmap_get(map, 7.5, hash_double, double_eq, 0.0);
  let v8 = hashmap_get(map, 8.0, hash_double, double_eq, 0.0);

  let v1 = int_of_float(v1);
  let v2 = int_of_float(v2);
  let v3 = int_of_float(v3);
  let v4 = int_of_float(v4);
  let v5 = int_of_float(v5);
  let v6 = int_of_float(v6);
  let v7 = int_of_float(v7);
  let v8 = int_of_float(v8);
  print_int(v1);
  print_int(v2);
  print_int(v3);
  print_int(v4);
  print_int(v5);
  print_int(v6);
  print_int(v7);
  print_int(v8);
}
