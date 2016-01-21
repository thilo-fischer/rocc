#ifndef TEST01_H
#define TEST01_H

// does this comment \
go on in this line?

/\
* Is this detected as comment? *\
/

/* does this comment *\/ go on * / until here ***/

/*is this ...*/#/*... and this ok? */if \
               /* foo */ \
1
#define DECLARE_INT(x) int /* part of macro? */ x
   \
 # \
 else \

#error
#endif

// should warn of whitespace \  
after backslash

#define foo unsigned \ // what now?
int i;

DECLARE_INT(i01);
DECLARE_INT(i02);

#define DECLARE_SHORT(X)short X
#define DECALRE_LONG(X)  long X

DECLARE_SHORT(s01);
DECALRE_LONG (l01);

#define FOO(A)
#define BAR (A)
#define BAZ/* . */(A)
#define QUX/* . */ (A)

#if 0
/*
#define SINGLEQUOTE '
#define DOUBLEQUOTE "
*/

//char a = SINGLEQUOTE SINGLEQUOTE;
//char b = ' SINGLEQUOTE;
//char c = SINGLEQUOTE ';

//char *d = DOUBLEQUOTE DECLARE_INT DOUBLEQUOTE;
//char *e = " DECLARE_INT DOUBLEQUOTE;
//char *f = DOUBLEQUOTE DECLARE_INT ";

// #define FOO 1020
/\
*
*/ # /*
*/ defi\
ne FO\
O 10\
20


#define foo01 "FOO01"
#define foo02 "FOO02"
#define foo03 foo04
#define foo04 "FOO04"
#define foo05 DOUBLEQUOTE foo01" DOUBLEQUOTE foo02"
#define foo06 "foo04"

char *x01 = DOUBLEQUOTE foo01" DOUBLEQUOTE foo02";
char *x02 = "foo01 DOUBLEQUOTE " foo02 DOUBLEQUOTE;

char *x03 = DOUBLEQUOTE foo03" DOUBLEQUOTE foo03" foo05;
char *x04 = DOUBLEQUOTE foo06" DOUBLEQUOTE foo03" foo05;

#endif

char c01 = 'f';
char c02 = '\'';
char c03 = '\t';
char c04 = '\032';

char *C01 = "foo\"bar";


// Can we forward declare types?
type my_type;
type int my_type;

enum my_enum;
typedef enum my_enum my_enum_type;
enum my_enum
    {
        foo,
        bar,
        baz
    };

struct my_struct;
typedef struct my_struct my_struct_type;
struct my_struct
    {
        int foo,
        unsigned int bar,
        const int baz
    };

union my_union;
typedef union my_union my_union_type;
union my_union
    {
        int foo,
        unsigned int bar,
        const int baz
    };

#endif // TEST01_H
