#include "lib.h"
#include <limits.h>
#include <math.h>
#include <stdalign.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void init_allocator() {}

void deinit_allocator() {}

static void allocation_panic(const char *message) {
  fprintf(stderr, "Allocation failed: %s\n", message);
  exit(EXIT_FAILURE);
}

int32_t minimbt_read_int() {
  int32_t value;
  scanf("%d", &value);
  if (ferror(stdin)) {
    fprintf(stderr, "Error reading integer input\n");
    return INT32_MIN; // Indicate error
  }
  return value;
}

int32_t minimbt_read_char() {
  int c = fgetc(stdin);
  return (c == EOF) ? -1 : (int32_t)c;
}

void minimbt_print_int(int32_t i) {
  printf("%d", i);
  fflush(stdout);
}

void minimbt_print_endline() {
  printf("\n");
  fflush(stdout);
}

void minimbt_print_char(int32_t ch) {
  if (ch >= 0 && ch <= 255) {
    putchar((char)ch);
  } else {
    putchar('?'); // Print replacement for invalid char
  }
  fflush(stdout);
}

int32_t minimbt_int_of_float(double f) {
  if (isnan(f) || f > (double)INT32_MAX || f < (double)INT32_MIN) {
    return 0; // Return 0 for NaN or out-of-range
  }
  return (int32_t)f; // Truncates towards zero
}

double minimbt_float_of_int(int32_t i) { return (double)i; }

int32_t minimbt_truncate(double f) { return minimbt_int_of_float(f); }

int32_t minimbt_floor(double f) {
  if (isnan(f)) {
    return 0;
  }
  double floor_val = floor(f);
  if (floor_val > (double)INT32_MAX || floor_val < (double)INT32_MIN) {
    return 0;
  }
  return (int32_t)floor_val;
}

double minimbt_abs_float(double f) { return fabs(f); }

double minimbt_sqrt(double f) { return sqrt(f); }

double minimbt_sin(double f) { return sin(f); }

double minimbt_cos(double f) { return cos(f); }

double minimbt_atan(double f) { return atan(f); }

uint8_t *minimbt_malloc(uint32_t sz) {
  if (sz == 0) {
    return NULL;
  }
  void *ptr = malloc(sz);
  if (ptr == NULL) {
    allocation_panic("minimbt_malloc");
  }
  return (uint8_t *)ptr;
}

static size_t safe_multiply_size(uint32_t count, size_t element_size) {
  if (count == 0)
    return 0;
  if (element_size > 0 && count > SIZE_MAX / element_size) {
    fprintf(stderr, "Integer overflow calculating allocation size (%u * %zu)\n",
            count, element_size);
    exit(EXIT_FAILURE);
  }
  return (size_t)count * element_size;
}

int32_t *minimbt_create_array(uint32_t n, int32_t v) {
  size_t total_size = safe_multiply_size(n, sizeof(int32_t));
  if (total_size == 0)
    return NULL;

  int32_t *arr = (int32_t *)malloc(total_size);
  if (arr == NULL) {
    allocation_panic("minimbt_create_array");
  }
  for (uint32_t i = 0; i < n; ++i) {
    arr[i] = v;
  }
  return arr;
}

void **minimbt_create_ptr_array(uint32_t n, void *init) {
  size_t total_size = safe_multiply_size(n, sizeof(void *));
  if (total_size == 0)
    return NULL;

  void **arr = (void **)malloc(total_size);
  if (arr == NULL) {
    allocation_panic("minimbt_create_ptr_array");
  }
  for (uint32_t i = 0; i < n; ++i) {
    arr[i] = init;
  }
  return arr;
}

double *minimbt_create_float_array(uint32_t n, double v) {
  size_t total_size = safe_multiply_size(n, sizeof(double));
  if (total_size == 0)
    return NULL;

  double *arr = (double *)malloc(total_size);
  if (arr == NULL) {
    allocation_panic("minimbt_create_float_array");
  }
  for (uint32_t i = 0; i < n; ++i) {
    arr[i] = v;
  }
  return arr;
}

// Checked Arithmetic
#if defined(__GNUC__) || defined(__clang__)
int32_t minimbt_checked_add(int32_t a, int32_t b) {
  int32_t res;
  if (__builtin_add_overflow(a, b, &res)) {
    fprintf(stderr, "Overflow adding %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return res;
}

int32_t minimbt_checked_sub(int32_t a, int32_t b) {
  int32_t res;
  if (__builtin_sub_overflow(a, b, &res)) {
    fprintf(stderr, "Overflow subtracting %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return res;
}

int32_t minimbt_checked_mul(int32_t a, int32_t b) {
  int32_t res;
  if (__builtin_mul_overflow(a, b, &res)) {
    fprintf(stderr, "Overflow multiplying %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return res;
}

#else
// Fallback manual checks
int32_t minimbt_checked_add(int32_t a, int32_t b) {
  if ((b > 0 && a > INT32_MAX - b) || (b < 0 && a < INT32_MIN - b)) {
    fprintf(stderr, "Overflow adding %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return a + b;
}

int32_t minimbt_checked_sub(int32_t a, int32_t b) {
  if ((b > 0 && a < INT32_MIN + b) || (b < 0 && a > INT32_MAX + b)) {
    fprintf(stderr, "Overflow subtracting %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return a - b;
}

int32_t minimbt_checked_mul(int32_t a, int32_t b) {
  long long temp_res = (long long)a * b;
  if (temp_res > INT32_MAX || temp_res < INT32_MIN) {
    fprintf(stderr, "Overflow multiplying %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  if ((a == INT32_MIN && b == -1) || (b == INT32_MIN && a == -1)) {
    fprintf(stderr, "Overflow multiplying %d and %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return (int32_t)temp_res;
}
#endif

int32_t minimbt_checked_div(int32_t a, int32_t b) {
  if (b == 0) {
    fprintf(stderr, "Divide by zero (%d / %d)\n", a, b);
    exit(EXIT_FAILURE);
  }
  if (a == INT32_MIN && b == -1) {
    fprintf(stderr, "Overflow dividing %d by %d\n", a, b);
    exit(EXIT_FAILURE);
  }
  return a / b;
}

// Compatibility Functions
void mincaml_print_int(int32_t i) { minimbt_print_int(i); }
void mincaml_print_endline() { minimbt_print_endline(); }
int32_t mincaml_int_of_float(double f) { return minimbt_int_of_float(f); }
double mincaml_float_of_int(int32_t i) { return minimbt_float_of_int(i); }
int32_t mincaml_truncate(double f) { return minimbt_truncate(f); }
int32_t mincaml_floor(double f) { return minimbt_floor(f); }
double mincaml_abs_float(double f) { return minimbt_abs_float(f); }
double mincaml_sqrt(double f) { return minimbt_sqrt(f); }
double mincaml_sin(double f) { return minimbt_sin(f); }
double mincaml_cos(double f) { return minimbt_cos(f); }
double mincaml_atan(double f) { return minimbt_atan(f); }
uint8_t *mincaml_malloc(uint32_t sz) { return minimbt_malloc(sz); }
int32_t *mincaml_create_array(uint32_t n, int32_t v) {
  return minimbt_create_array(n, v);
}
void **mincaml_create_ptr_array(uint32_t n, void *init) {
  return minimbt_create_ptr_array(n, init);
}
double *mincaml_create_float_array(uint32_t n, double v) {
  return minimbt_create_float_array(n, v);
}
