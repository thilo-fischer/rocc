# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/file_represented/filesystem_element'

module Rocc::CodeElements::FileRepresented

  require 'digest/sha1'
  
  ##
  # Represet a source code file.
  class CeFile < CeFilesystemElement

    attr_reader :adducer, :basename, :extension

    def initialize(parent_dir, adducer, basename, extension)
      super(parent_dir, basename)
      @adducer = adducer
      @extension = extension
      @mod_time = nil
      @checksum = nil
    end

    alias basename name

    def name
      if @extension
        basename + '.' + @extension
      else
        basename
      end
    end
   
#    def symbols(filter = nil)
#      if @symbols and up_to_date?
#        @symbols
#      else
#        raise "Cannot parse single file on its own, need translation unit context"
#      end
#    end
    

    def lines
      unless @lines and up_to_date?
        update_changedetection
        File.open(abs_path, "r") do |file|
          @lines = file.readlines.map(&:chomp!)
        end
      end
      @lines
    end # lines

    def content
      unless @content and up_to_date?
        @content = []
        lines.each_with_index do |ln, idx|
          @content << CoPhysicLine.new(self, ln, idx)
        end
      end
      @content
    end

    def pursue(parsing_context)
      super(parsing_context.lineread_context)
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
      File.mtime(abs_path)
    end
    
    ##
    # Get the file's current SHA1 checksum. Read from file system,
    # do not return any eventually buffered values.
    def volatile_checksum
      Digest::SHA1.hexdigest(IO.read(abs_path))
    end

    def change_detection_mtime?
      $options.value(:change_detection).include?("mtime")
    end

    def change_detection_sha1?
      $options.value(:change_detection).include?("sha1")
    end

  end # class CeFile

end # module Rocc::CodeElements::FileRepresented
