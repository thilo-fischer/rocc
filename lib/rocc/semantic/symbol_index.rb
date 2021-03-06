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

require 'rocc/session/logging'

require 'rocc/code_elements/code_element'

module Rocc::Semantic

  class SymbolIndex

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    def initialize
      @symbols = {}
    end
    
    def announce_symbol(symbol)
      log.info{"SymbolIndex#announce_symbol: #{symbol}"}
      id_array = @symbols[symbol.identifier] ||= []
      id_array << symbol
    end

    def announce_symbols(other_idx)
      # TODO_F room for improvement ...
      other_idx.find_symbols({}).each {|s| announce_symbol(s)}
    end

    ##
    # Returns an array of all symbols found in this index that match
    # the given critaria. Returns an empty array if no such symbol
    # found.
    #
    # If +criteria+ is a CeSymbol, all symbols +s+ with
    # <tt>s == criteria</tt> are being returned.
    #
    # If +criteria+ is a hash, all symbols +s+ with
    # <tt>s.match(criteria)</tt> are being returned.
    # See CeSymbol#match for details.
    def find_symbols(criteria)
      if criteria.is_a?(CeSymbol)
        find_symbols_ce_symbol(criteria)
      else
        find_symbols_hash(criteria)
      end
    end

    def find_symbols_ce_symbol(symbol)
      symbols_matching_id = @symbols[symbol.identifier]
      if symbols_matching_id
        result = symbols_matching_id.select do |s|
          s == symbol
        end
        raise unless result.length <= 1
        result
      else
        []
      end
    end
    private :find_symbols_ce_symbol

    def find_symbols_hash(criteria)
      
      primary_crit_copy = criteria.dup # XXX_F(assert) deleting entries from criteria hash to ensure all entries get handled requires copying of criteria hash which decreases performance
      identifier = primary_crit_copy.delete(:identifier)

      #@symbols.values.each {|s| warn "\tsymbol #{s.name_dbg}"}

      symbols_matching_id = find_symbols_identifier(identifier)

      result = symbols_matching_id.select do |s|
        #warn "symbols with according identifier: #{s.name_dbg}"
        # FIXME duplication of criteria decreases performance
        crit_copy = primary_crit_copy.dup
        match = s.match(crit_copy)
        raise "unhandled criteria (not yet supported?): #{crit_copy.keys}" if match and not crit_copy.empty?
        match
      end

      log.info do
        crit_str = criteria.map do |key, value|
          "#{key}: " +
            case value
            when Array
              "[#{value.map {|e| e.to_s}.join(', ')}]"
            when Rocc::CodeElements::CodeElement
              value.name_dbg
            else
              value.to_s
            end
        end.join(', ')
        "Idx#find_symbols: #{result.count} symbols (of #{symbols_matching_id.count} with id match) matching {#{crit_str}}"
      end
      log.debug{" \u21AA #{result.map {|s| s.name_dbg}}"} unless result.empty?
      result
    end
    private :find_symbols_hash

    def find_symbols_identifier(identifier)
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
    end
    private :find_symbols_identifier
    
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
