
typedef int my_type;

// syntactically equivallent declarations will be interpreted differently depending on available type definitions

my_type     (my_variable  );

my_function (argument_name);


void foo(void) {

    my_variable = 42;

    my_function(42);

}



#if 0

// gcc -S -D VARIANT=0

#if VARIANT & 1
typedef int foo;
#endif

#if VARIANT & 2
typedef int bar;
#endif

foo(bar);

void baz(void) {

    foo(42);

    bar = 42;

}

#endif
