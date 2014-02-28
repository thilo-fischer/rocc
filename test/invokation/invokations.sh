#!/bin/bash

set -ex

./ooccor.rb --help 2>&1 | grep -iE 'usage:[[:space:]]*ooccor.rb'

./ooccor.rb -c foobar 2>&1 | grep -iE 'invalid'

./ooccor.rb -c gcc -j -k -q -z 2>&1 | grep -iE 'unsupported compiler argument'


echo -e '\n\n*** GREEN :) ***\n'
