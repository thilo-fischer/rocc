/*
 * C code to be used when testing rocc.
 *
 * Code declaring and defining many different kinds of symbols.
 * (Within rocc, we also understand macro names as symbols.)
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

struct counting_s;

char hello[];

static void print_char(char);
void print_all_chars(const char* string);

// type definistions

struct counting_s {
  int cur;
  int max;
};

typedef struct counting_s counting_t;

// constant definitions

const char SPACE = ' ';
const char *WORLD = "world";

// variable definitions

char hello[MAX_STRLEN];

static counting_t counting = {0};

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
    counting.max = argc;
    for (counting.cur = 1; counting.cur < counting.max; ++counting.cur) {
      strncpy(hello, HELLO(counting.cur == 1), MAX_STRLEN);
      print_all_chars(hello);
      print_n_chars(&SPACE, 1);
      print_all_chars(argv[counting.cur]);
      print_char(PUNCTUATION(counting.cur < counting.max - 1));
      new_line();
    }
  }
}
