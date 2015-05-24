/*
 * C code to be used when testing ooccor.
 *
 * Code declaring and defining many different kinds of symbols.
 * (Within ooccor, we also understand macro names as symbols.)
 *
 * Prints "Hello world!" and similar a circuitous way ...
 *
 * Released into the public domain.
 */

#include <stdio.h>
#include <string.h>

// macros

#define MAX_STRLEN 256

#define UPPERCASE_H "H"
#define LOWERCASE_H "h"
#define HELLO_H_SUFFIX "ello"

#define HELLO(uppercase)			\
  (uppercase ?					\
   (UPPERCASE_H HELLO_H_SUFFIX) :		\
   (LOWERCASE_H HELLO_H_SUFFIX)			\
   )

#define PUNCTUATION(continue)			\
  (continue ? ',' : '!')

// forward declarations

char hello[];
static int count;
int max_count;

static void print_char(char);
void print_all_chars(const char* string);

// constant definitions

const char SPACE = ' ';
const char *WORLD = "world";

// variable definitions

char hello[MAX_STRLEN];

static int count;
int max_count = 0;

// function definitions

static void print_char(char c) {
  printf("%c", c);
}

static void new_line(void) {
  printf("\n");
}

void print_n_chars(const char* string, size_t n) {
  int i;
  for (i = 0; i < n; ++i) {
    print_char(string[i]);
  }
}

void print_all_chars(const char* string) {
  print_n_chars(string, strnlen(string, MAX_STRLEN));
}

int main(int argc, char **argv) {
  strncpy(hello, HELLO(1), MAX_STRLEN);
  if (argc == 1) {
    print_all_chars(hello);
    print_n_chars(&SPACE, 1);
    print_all_chars(WORLD);
    print_char(PUNCTUATION(0));
    new_line();
  } else {
    max_count = argc;
    for (count = 1; count < max_count; ++count) {
      strncpy(hello, HELLO(count == 1), MAX_STRLEN);
      print_all_chars(hello);
      print_n_chars(&SPACE, 1);
      print_all_chars(argv[count]);
      print_char(PUNCTUATION(count < max_count - 1));
      new_line();
    }
  }
}
