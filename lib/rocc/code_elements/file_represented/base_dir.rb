# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisly the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/code_elements/file_represented/dir'

module Rocc::CodeElements::FileRepresented

  ##
  # Represet the root directory of a source tree that is part of the current target source code.
  class CeBaseDirectory < CeDirectory

    attr_reader :path, :abs_path

    ##
    #--
    # FIXME adducer sensible?
    def initialize(adducer, path)
      name = File::basename(path)
      super(nil, name)
      @path = path
      @abs_path = File::expand_path(path)
    end

    # Overwrite the CeFilesystemElement's implementation of parent_dir, return always nil.
    def parent_dir
      nil
    end

    def has_parent_dir?
      false
    end
    
    def is_base_dir?
      true
    end
    
    def rel_path
      '+/' + name # use '+' as symbol for base directories ..?
    end

  end # class CeBaseDirectory

end # module Rocc::CodeElements::FileRepresented
