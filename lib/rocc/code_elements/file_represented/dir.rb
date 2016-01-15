# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/file_represented/filesystem_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Represet a directory where source files reside in.
  class CeDirectory < CeFilesystemElement

    attr_reader :content

    def initialize(origin, name)
      super
      @content = []
    end

    def add_fs_element(filesystem_element)
      @content << filesystem_element
    end

    def adducer
      # XXX return array of all files in this dir and its subdirectories?
      @content
    end
    
#    protected
#    # to be used from CeBaseDirectory::initialize
#    def initialize(origin)
#      super
#    end

  end # class CeDirectory

end # module Rocc::CodeElements::FileRepresented
