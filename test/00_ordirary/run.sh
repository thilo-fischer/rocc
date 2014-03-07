#!/bin/bash

set -ex

ruby -w --debug ./bin/ooccor -e "ls -1" ./test/00_ordirary/indented_hello_world_00.c 2>&1 > /tmp/ooccur-test.$$
echo <<EOF | diff /tmp/ooccur-test.$$
MAX_INDENTATION
ARG_TO_STR
INDENT_META_FORMAT
MAX_INDENT_FORMAT
print_indented
main
EOF


echo -e '\n\n*** GREEN :) ***\n'
