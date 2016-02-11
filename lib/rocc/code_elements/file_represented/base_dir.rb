# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/code_elements/file_represented/dir'

module Rocc::CodeElements::FileRepresented

  ##
  # Represet the root directory of a source tree that is part of the current target source code.
  class CeBaseDirectory < CeDirectory

    attr_reader :path_full, :path_abs

    def initialize(path, adducer = nil)
      name = File::basename(path)
      super(nil, name)
      @adducer = adducer
      @path_full = path
      @path_abs = File::expand_path(path)
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "BaseDir[#{name}]"
    end

    def path
      '.../' + name
    end

    def adducer
      @adducer || super
    end

  end # class CeBaseDirectory

end # module Rocc::CodeElements::FileRepresented
