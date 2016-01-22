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

require 'rocc/code_elements/code_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Base class to represet input files and the directories these files
  # reside in.
  class CeFilesystemElement < Rocc::CodeElements::CodeElement

    attr_reader :name

    ##
    # For all CeFilesystemElements (except for CeBaseDirectories),
    # origin represents the parent directory.
    alias parent_dir origin

    ##
    # +origin+ is the CeDirectory element representing the objects
    # parent direcotery (or a symbol representing the adducer or nil
    # for base directories).
    #
    # +name+ is the element's base name as a string.
    def initialize(origin, name)
      super(origin)
      @name = name
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "FsE[#{name}]"
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#path_separator
    def path_separator
      "/"
    end
    private :path_separator

    # See rdoc-ref:Rocc::CodeElements::CodeElement#location
    #--
    # XXX aliases not listed in rdoc ?!
    # alias location path
    def location; path; end

    def is_base_dir?
      self.class.is_a? CeBaseDirectiory
    end

  end # class CeFilesystemElement

end # module Rocc::CodeElements::FileRepresented
