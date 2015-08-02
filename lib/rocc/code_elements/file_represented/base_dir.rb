# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/file_represented/dir'

module Rocc::CodeElements::FileRepresented

  ##
  # Represet the root directory of a source tree that is part of the current target source code.
  class CeBaseDirectory < CeDirectory

    attr_reader :path, :abs_path
    
    def initialize(origin, path)
      super(origin)
      @path = path
      @abs_path = File::expand_path(path)
    end

    def rel_path
      '.'
    end

  end # class CeBaseDirectory

end # module Rocc::CodeElements::FileRepresented
