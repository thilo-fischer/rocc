# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeElements::FileRepresented

  ##
  # Represet a directory where source files reside in.
  class CeDirectory < CeFilesystemElement

    def initialize(parent_dir, name)
      super
      @content = []
    end

    def add_fs_element(filesystem_element)
      @content << filesystem_element
    end

#    protected
#    # to be used from CeBaseDirectory::initialize
#    def initialize(origin)
#      super
#    end

  end # class CeDirectory

end # module Rocc::CodeElements::FileRepresented
