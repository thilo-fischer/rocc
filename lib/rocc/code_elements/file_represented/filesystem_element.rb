# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeElements::FileRepresented

  ##
  # Base class to represet input files and the directories these files
  # reside in.
  class CeFilesystemElement < CodeElement

    attr_reader :name

    def initialize(parent_dir, name)
      super(parent_dir)
      @name = name
    end

    alias parent_dir origin

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
