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

require 'rocc/session/logging'

module Rocc::Semantic

  class SymbolIndex

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    def initialize
      @symbols = {}
    end
    
    def announce_symbol(symbol)
      warn "SymbolIndex#announce_symbol: #{symbol}"
      id_array = @symbols[symbol.identifier] ||= []
      id_array << symbol
    end

    def announce_symbols(other_idx)
      # TODO_F room for improvement ...
      other_idx.find_symbols({}).each {|s| announce_symbol(s)}
    end

    # Returns an array of all symbols found in this index that match
    # the given critaria. Returns an empty array if no such symbol
    # found. family specifies whether the symbol shall be a
    # variable/function/macro/typedef/..., argument shall be the
    # according subclass of CeSymbol corresponding to the appropriate
    # familiy. linkage may specifiy the desired linkage of the symbol
    # if applicable (elements from some families don't have any
    # linkage). conditions specifies the conditions to be assumed for
    # preprocessor conditionals (+existence_conditions+ of the
    # symbol).
    def find_symbols(criteria)
      original_criteria = criteria.dup # XXX for dbg message only
      identifier = criteria.delete(:identifier)

      #@symbols.values.each {|s| warn "\tsymbol #{s.name_dbg}"}

      symbols_matching_id =
        case identifier
        when nil
          @symbols.values.flatten
        when String
          @symbols[identifier] || []
        when Regexp
          @symbols.select {|key, value| key =~ identifier}.values.flatten
        else
          raise
        end

      result = symbols_matching_id.select do |s|
        #warn "symbols with according identifier: #{s.name_dbg}"
        # FIXME duplication of criteria decreases performance
        crit_copy = criteria.dup
        match = s.match(crit_copy)
        raise "unhandled criteria (not yet supported?): #{crit_copy.keys}" if match and not crit_copy.empty?
        match
      end

      log.info{"SymbolInex#find_symbols: #{result.count} out of #{symbols_matching_id.count} symbols matching identifier #{original_criteria[:identifier].inspect} match #{original_criteria}"}
      log.debug{" \u21AA #{result.map {|s| s.name_dbg}}"}
      
      result
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
