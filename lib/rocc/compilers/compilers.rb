# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Compilers

  require 'rocc/compilers/compiler'
  require 'rocc/compilers/gcc'

  $supported_compilers = { :gcc => Gcc }

end # module Rocc::Compilers
