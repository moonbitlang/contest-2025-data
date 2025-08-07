#include <stdio.h>

void print_int(int v) {
   printf("%d", v);
}
void print_double(double v) {
   printf("%f", v);
}

void print_endline() {
   printf("\n");
}

int int_of_float(double x) {
   return (int)x;
}

double float_of_int(int x) {
   return (double)x;
}

int truncate(double f) {
   return (int)f;
}

double abs_float(double f) {
   return f < 0 ? -f : f;
}
