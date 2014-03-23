# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::Compilers

require 'ooccor/compilers/compiler'
require 'ooccor/compilers/gcc'

$supported_compilers = { :gcc => CompilerGcc }

end # module Ooccor::Compilers
