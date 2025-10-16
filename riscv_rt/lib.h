#ifndef LIB_H
#define LIB_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void init_allocator();
void deinit_allocator();

// Exported functions
int32_t minimbt_read_int();
int32_t minimbt_read_char();
void minimbt_print_int(int32_t i);
void minimbt_print_endline();
void minimbt_print_char(int32_t ch);
int32_t minimbt_int_of_float(double f);
double minimbt_float_of_int(int32_t i);
int32_t minimbt_truncate(double f);
int32_t minimbt_floor(double f);
double minimbt_abs_float(double f);
double minimbt_sqrt(double f);
double minimbt_sin(double f);
double minimbt_cos(double f);
double minimbt_atan(double f);
uint8_t *minimbt_malloc(uint32_t sz);
int32_t *minimbt_create_array(uint32_t n, int32_t v);
void **minimbt_create_ptr_array(uint32_t n, void *init);
double *minimbt_create_float_array(uint32_t n, double v);

int32_t minimbt_checked_add(int32_t a, int32_t b);
int32_t minimbt_checked_sub(int32_t a, int32_t b);
int32_t minimbt_checked_mul(int32_t a, int32_t b);
int32_t minimbt_checked_div(int32_t a, int32_t b);

// Compatibility functions
void mincaml_print_int(int32_t i);
void mincaml_print_endline();
int32_t mincaml_int_of_float(double f);
double mincaml_float_of_int(int32_t i);
int32_t mincaml_truncate(double f);
int32_t mincaml_floor(double f);
double mincaml_abs_float(double f);
double mincaml_sqrt(double f);
double mincaml_sin(double f);
double mincaml_cos(double f);
double mincaml_atan(double f);
uint8_t *mincaml_malloc(uint32_t sz);
int32_t *mincaml_create_array(uint32_t n, int32_t v);
void **mincaml_create_ptr_array(uint32_t n, void *init);
double *mincaml_create_float_array(uint32_t n, double v);

#endif // LIB_H
