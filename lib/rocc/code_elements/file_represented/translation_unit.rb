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

    ##
    # Parse translation unit's main source file. (Implies parsing all
    # files included from the main file with the +#include+
    # directive.)
    #
    # Will do the parsing no matter if the symbol table is already
    # available and up to date. Test with +up_to_date?+ 
    def populate
      ctx = ParsingContext.new(self)
      main_file.pursue(ctx)
      cxt.terminate
    end

    ##
    # Get all symbols found in this translation unit. Restrict to only
    # those symbols matching specific criteria if filter is given.
    #
    # Includes updating the translation unit's symbol table if symbol
    # table has not yet been created or is outdated (due to
    # translation unit's files having been changed).
    def symbols(filter = nil)
      # update symbols if not yet populated or outdated (lazy loading -- sort of ...)
      unless @symbols and up_to_date?
        populate
      end
      
      if filter
        # TODO Take filter into account.
        # TODO Make filter an optional block and use select method?
        raise "Not yet supported" # TODO
      else
        @symbols
      end
    end

    ##
    # Check if files of this translation unit changed on disk.
    def up_to_date?
      # If symbol table is not (yet) available, return false.
      # (Normally checked implicitly by +up_to_date?+ because the main
      # file's +@mod_time+ and/or +@checksum+ would be +nil+ as long
      # as +@symbols+ is nil; this logic will fail though when one
      # translation unit's main file +#include+s the main file of
      # another translation unit.)
      return false unless @symbols
      # If the main file has changed, return false.
      return false unless main_file.up_to_date?
      # If none of the files included from the main file (directly or
      # indirectly) has changed, return true. Otherwise (if at least
      # one file changed), return false.
      return not @include_files.find { |incfile| not incfile.up_to_date? }
    end

  end # class CeTranslationUnit

end # module Rocc::CodeElements::FileRepresented
