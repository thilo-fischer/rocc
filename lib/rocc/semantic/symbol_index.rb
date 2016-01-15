# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/code_element'

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
    
    def find_symbols(identifier, namespace = nil, family = nil, linkage = nil, conditions = nil)
      #FIXME apply filters for namespace, familiy etc.
      @symbols[identifier]
    end

    def find_innermost_symbol(identifier, namespace = nil, family = nil, linkage = nil, conditions = nil)
      matched_symbols = find_symbols(identifier, namespace, family, linkage, conditions)
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
