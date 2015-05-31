# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeElements::FileRepresented

  require 'digest/sha1'
  
  ##
  # Represet a directory where source files reside in.
  class CeFile < CeFilesystemElement

    attr_reader :adducer, :basename, :extension

    def initialize(parent_dir, adducer, basename, extension)
      super(parent_dir, basename)
      @adducer = adducer
      @extension = extension
      @mod_date = nil
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

    def parse(context)
      mod_date = File.mtime(abs_path)
      if mod_date == @mod_date
        $log.debug { "Modification date of #{self} not changed, probably no update required." } # TODO
      else
        $log.debug { "Modification date of #{self} changed, update required." } # TODO
        @mod_date = mod_date
      end
      
      checksum = Digest::SHA1.hexdigest(IO.read(abs_path))
      if checksum == @checksum
        $log.debug { "Checksum of #{self} not changed, probably no update required." } # TODO
      else
        $log.debug { "Checksum of #{self} changed, update required." } # TODO
        @checksum = checksum
      end

      
      # FIXME
    end


  def lines
    unless @lines
      File.open(abs_path, "r") do |file|
        @lines = file.readlines.map(&:chomp!)
      end
    end
    @lines
  end # lines

  def content
    unless @content
      @content = []
      lines.each_with_index do |ln, idx|
        @content << CoPhysicLine.new(self, ln, idx)
      end
    end
    @content
  end

    
  end # class CeFile

end # module Rocc::CodeElements::FileRepresented
