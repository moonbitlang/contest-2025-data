#include <stdlib.h> // For EXIT_SUCCESS

extern void minimbt_main();

int main() {

  // Call the main entry point of the compiled language code
  minimbt_main();

  return EXIT_SUCCESS; // Indicate successful execution
}
