#!/bin/bash

export PATH="$PATH:../bin"
export RUBYLIB="$RUBYLIB:../lib"

set -ex

./invokation/command-help.sh
./invokation/invokations.sh

./00_ordirary/run.sh

echo -e "\n\n*** ALL GREEN :) ***\n"
