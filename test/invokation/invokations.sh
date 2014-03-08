#!/bin/bash

set -ex

ooccor --help
ooccor --help 2>&1 | grep -iE 'usage:[[:space:]]*ooccor'

! ooccor -c foobar
ooccor -c foobar 2>&1 | grep -iE 'invalid'

echo | ooccor -c gcc -j -k -q -z
echo | ooccor -c gcc -j -k -q -z 2>&1 | grep -iE 'unsupported compiler argument'


echo -e "\n*** $0 GREEN :) ***\n"
