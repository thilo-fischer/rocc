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

require 'rocc/code_elements/code_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Base class to represet input files and the directories these files
  # reside in.
  class CeFilesystemElement < Rocc::CodeElements::CodeElement

    attr_reader :name

    ##
    # origin is the CeDirectory element representing the objects
    # parent direcotery (or nil or a symbol representing the adducer
    # for base directories).
    #
    # name is the file name as a string.
    def initialize(origin, name)
      super(origin)
      @name = name
    end

    # For all CeFilesystemElements except for CeBaseDirectories, origin represents the parent directory.
    alias parent_dir origin
    alias has_parent_dir? origin

    def is_base_dir?
      false
    end
    
    # Relative path of this element wrt its base directory.
    def rel_path
      parent_dir.rel_path + '/' + name
    end

    # Absolute path of this element.
    def abs_path
      parent_dir.abs_path + '/' + name
    end

    # Path of this element as specified from build setup and source code.
    def path
      parent_dir.path + '/' + name
    end

  end # class CeFilesystemElement

end # module Rocc::CodeElements::FileRepresented
