# -*- coding: utf-8 -*-

require_relative 'Compiler'

require_relative 'gcc'

$supported_compilers = { :gcc => CompilerGcc }
