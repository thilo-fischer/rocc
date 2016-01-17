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
      case identifier
      when String
        @symbols[identifier]
      when RegExp
        @symbols.values.find {|s| s.identifier =~ identifier}
      else
        raise
      end
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
