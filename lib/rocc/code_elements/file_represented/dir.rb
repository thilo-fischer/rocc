# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/code_elements/file_represented/filesystem_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Represet a directory where source files reside in.
  class CeDirectory < CeFilesystemElement

    def initialize(origin, name)
      super
      @elements = {}
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "Dir[#{name}]"
    end

    def add_child(filesystem_element)
      @elements[filesystem_element.name] = filesystem_element
    end

    def find_child(name)
      @elements[name]
    end

    def content
      @elements.values
    end
    
    alias adducer content

    def self.from_path(path)
      raise "TODO"
      # adapt implementation from Session#ce_file
    end
    
  end # class CeDirectory

end # module Rocc::CodeElements::FileRepresented
