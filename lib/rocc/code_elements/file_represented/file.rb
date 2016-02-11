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

require 'rocc/code_elements/file_represented/filesystem_element'
require 'rocc/code_elements/char_represented/physic_line.rb'

module Rocc::CodeElements::FileRepresented

  require 'digest/sha1'
  
  ##
  # Represet a source code file.
  class CeFile < CeFilesystemElement

    # Filename extension (including the introductory '.' character)
    attr_reader :extension
    # Array of all the "causes" for this file to be visited.
    attr_reader :adducer

    ##
    # +origin+ is the CeDirectory element representing directory the
    # file resides in.
    #
    # +name+: Filename including extension, without any directory
    # prefix.
    #
    # +adducer+: The "cause" for this file to be visited.
    def initialize(origin, name, adducer)
      super(origin, name)
      if adducer.is_a? Array
        @adducer = adducer
      else
        @adducer = [ adducer ]
      end
      @extension  = File::extname(name)
      @mod_time = nil
      @checksum = nil
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "File[#{name}]"
    end

    def basename
      File::basename(name, @extension)
    end
   
#    def symbols(filter = nil)
#      if @symbols and up_to_date?
#        @symbols
#      else
#        raise "Cannot parse single file on its own, need translation unit context"
#      end
#    end
    
    ##
    # Array of Strings representing the lines contained in this file.
    def lines
      unless @lines and up_to_date?
        update_changedetection
        File.open(path_full, "r") do |file|
          @lines = file.readlines
        end
      end
      @lines
    end # lines

    ##
    # Array of CePhysicLine objects representing the contained lines.
    def content
      unless @content and up_to_date?
        @content = []
        lines.each_with_index do |ln, idx|
          @content << Rocc::CodeElements::CharRepresented::CePhysicLine.new(self, ln, idx)
        end
      end
      @content
    end

    def pursue(lineread_context)
      super(lineread_context)
    end

    private
    
    ##
    # Test if file changed since we parsed it the last time.
    #
    # The mechanism to detect file changes can be controlled via
    # +--change-detection+ option.
    # [+mtime+] Test if the file's
    #   current modification timestamp differs from its timestamp when
    #   it was parsed the last time. This is the default.
    # [+sha1+] Test if the file's current SHA1 checksum 
    #   differs from its checksum when it was parsed the last time.
    # [+mtime+sha1+] If no change detected with the +mtime+ mechanism,
    #   also test for change using the +sha1+ mechanism.
    #--
    # XXX We will read the date and compute the checksum more often
    # than necessary (twice instead of once): once to check if file is
    # up to date, and once more if the file changed after the
    # according CodeElements were updated at update_changedetection.
    def up_to_date?
      if change_detection_mtime?
        return false if @mod_time != volatile_mod_time
      end

      if change_detection_sha1?
        return false if @checksum != volatile_checksum
      end

      return true
    end

    ##
    # Update modification timestamp and checksum values used to detect
    # file modification to the values given as parameters or to the
    # values calculated for the current version of the file.
    def update_changedetection(mod_time = nil, checksum = nil)
      if change_detection_mtime?      
        @mod_time = mod_time || volatile_mod_time
      end
      if change_detection_sha1?
        @checksum = checksum || volatile_checksum
      end
    end

    ##
    # Get the most recently recorded mtime.
    def known_mod_time
      @mod_time
    end
    
    ##
    # Get the most recently recorded checksum.
    def known_checksum
      @checksum
    end
    
    ##
    # Get the file's current modification date. Read from file system,
    # do not return any eventually buffered values.
    def volatile_mod_time
      File.mtime(path_full)
    end
    
    ##
    # Get the file's current SHA1 checksum. Read from file system,
    # do not return any eventually buffered values.
    def volatile_checksum
      Digest::SHA1.hexdigest(IO.read(path_full))
    end

    def change_detection_mtime?
      Rocc::Session::Session::current_session.options.value(:change_detection).include?("mtime")
    end

    def change_detection_sha1?
      Rocc::Session::Session::current_session.options.value(:change_detection).include?("sha1")
    end

  end # class CeFile

end # module Rocc::CodeElements::FileRepresented
