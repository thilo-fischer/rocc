# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/code_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Represents translation units. A translation unit usually
  # corresponds to an object file being created during compilation.
  class CeTranslationUnit < CodeElement

    attr_reader :include_files

    def initialize(main_file)
      super(main_file)
      @include_files = []
    end

    alias main_file origin

    def add_include_file(file)
      @include_files << file
    end

    def name
      main_file.basename + ".o"
    end

    def populate
      ctx = ParsingContext.new(self)
      main_file.pursue(ctx)
      cxt.terminate
    end

    def symbols(filter = nil)
      # TODO Take filter into account.
      # TODO Make filter an optional block and use select method?
      unless @symbols and up_to_date?
        populate
      end
      @symbols
    end
    
    ##
    # Check if files of this translation unit changed on disk.
    def up_to_date?
      return false unless main_file.up_to_date?
      not @include_files.find { |incfile| not incfile.up_to_date? }
    end

  end # class CeTranslationUnit

end # module Rocc::CodeElements::FileRepresented
