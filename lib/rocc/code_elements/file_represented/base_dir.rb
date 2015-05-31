# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeElements::FileRepresented

  ##
  # Represet a directory where source files reside in.
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
