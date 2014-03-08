#!/bin/bash

set -ex

echo | ooccor -e "help"
echo | ooccor -e "help" 2>&1 | grep -iE 'ls.*list'

echo | ooccor -e "help help"
echo | ooccor -e "help help" 2>&1 | grep -iE 'usage:[[:space:]]*help '

echo | ooccor -e "help help ls"
echo | ooccor -e "help help ls" 2>&1 | grep -iE 'usage:[[:space:]]*help '
echo | ooccor -e "help help ls" 2>&1 | grep -iE 'usage:[[:space:]]*ls '

echo -e "\n*** $0 GREEN :) ***\n"
