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

require 'rocc/code_elements/file_represented/base_dir'
require 'rocc/code_elements/file_represented/dir'
require 'rocc/code_elements/file_represented/file'

module Rocc::CodeElements::FileRepresented

  ##
  # Represet a directory where source files reside in.
  class FilesystemElementIndex

    def initialize
      @elements = {}
      @base_directories = {}
    end

    def announce_element(element_class, path, adducer = nil)
      #warn " * #{caller[1]} announce: #{element_class} #{path} #{adducer}"
      #raise if path == "/"
        
      # "normalize" path
      path_abs = File.expand_path(path)

      # base directroies need special treatment
      if element_class <= CeBaseDirectory
        basedir = @base_directories[path_abs]
        if basedir
          basedir.add_adducer(adducer) if adducer
        else
          basedir = CeBaseDirectory.new(path, adducer)
          @base_directories[path_abs] = basedir
          # TODO if basedir is parent directory of another dir already
          # included in base_directories, remove that other base
          # directory from base_directories and substitute its
          # references to basedir's according child dircetories
        end
        return basedir
      else
        
        # if element already exists, return that instance
        element = @elements[path_abs]
        if element
          element.add_adducer(adducer) if adducer
          return element
        end
        
        # find the base dir this element falls into
        basedir = @base_directories.keys.find do |b|
          File.fnmatch(b.path_abs + "**", path_abs, File::FNM_PATHNAME)
        end

        # if not found, announce parent dir as base dir
        basedir = announce_element(CeBaseDirectory, File.dirname(path)) unless basedir

        basename = File.basename(path_abs)
        dirpath  = File.dirname(path_abs)
        
        raise "Programming error :(" unless dirpath.start_with?(basedir.path_abs)

        # determine directory levels from base dir to element's parent dir
        dirpath.slice!(basedir.path_abs)
        dirpath.gsub!(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
        dirnames = dirpath.split(File::SEPARATOR)

        # ensure all directories from base dir to element exist
        parent_dir = dirnames.inject(basedir) do |parent, name|
          child = parent.find_child(name)
          unless child
            child = CeDirectory.new(parent, name)
            parent.add_child(child)
            @elements[child.path_abs] = child # XXX smells => recursively use announce?
          end
          child
        end

        result = CeFile.new(parent_dir, basename, adducer)
        @elements[path_abs] = result
      end
      
    end # def announce_element

  end # class FilesystemElementIndex

end # module Rocc::CodeElements::FileRepresented
