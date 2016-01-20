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

module Rocc::Semantic

  class SymbolIndex

    def initialize
      @symbols = {}
    end
    
    def announce_symbol(symbol)
      if @symbols.key?(symbol.identifier)
        @symbols[symbol.identifier] << symbol
      else
        @symbols[symbol.identifier] = [ symbol ]
      end
    end

    # Returns an array of all symbols found in this index that match
    # the given critaria. Returns an empty array if no such symbol
    # found. family specifies whether the
    # symbol shall be a variable/function/macro/typedef/..., argument
    # shall be the according subclass of CeSymbol corresponding to the
    # appropriate familiy. linkage may specifiy the desired linkage of
    # the symbol if applicable (elements from some families don't have
    # any linkage). conditions specifies the conditions to be assumed
    # for preprocessor conditionals.
    def find_symbols(identifier, family = nil, linkage = nil, conditions = nil)
      #FIXME apply filters for familiy, linkage etc.
      case identifier
      when String
        @symbols[identifier] || []
      when RegExp
        @symbols.values.select {|s| s.identifier =~ identifier}
      else
        raise
      end
    end

    #--
    # XXX move functions find_innermost_symbol, find_function etc. (wrappers for find_symbols) to mixin class to be included by CompilationContext, CompilationBranch, TranslationUnit etc. as well
    
    def find_innermost_symbol(identifier, family = nil, linkage = nil, conditions = nil)
      matched_symbols = find_symbols(identifier, family, linkage, conditions)
      if matched_symbols
        # FIXME the last in the array is NOT the innermost! (Take Session::cursor into account?)
        matched_symbols.last
      end
    end
    
    def find_function(identifier, linkage = external, conditions = nil)
      find_innermost_symbol(identifier, :ordinary, CeFunction, linkage, conditions)
    end
    
    def find_variable(identifier, linkage = external, conditions = nil)
      find_innermost_symbol(identifier, :ordinary, CeVariable, linkage, conditions)
    end
    
    def find_macro(identifier, conditions = nil)
      find_innermost_symbol(identifier, :macros, CeMacro, nil, conditions)
    end
    
  end # class SymbolIndex

end # module Rocc::Semantic
