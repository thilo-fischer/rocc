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

  class CeSymbol < Rocc::CodeElements::CodeElement

    attr_reader :identifier, :adducers, :existence_conditions

    # origin is the unit the symbol lives in, e.g. the translation
    # unit it belongs to.  identifier is the symbols name.
    def initialize(origin, identifier, conditions, hashargs)
      raise "unprocessed hashargs: #{hashargs.inspect}" unless hashargs.empty? # XXX defensive progamming => remove some day
      super(origin)
      @identifier = identifier
      @existence_conditions = conditions
      log.info{"new symbol #{self} in #{origin} given #{conditions}"}
    end # initialize

    def name
      "symbol `#{@identifier}'"
    end
    
    def name_dbg
      "Sym[#{@identifier}]"
    end

    def self.family_name
      family.to_s
    end
    
    def existence_probability
      existence_conditions.probability
    end

    def match(criteria)
      #warn "XXXX #{name_dbg} -> match: #{criteria}"
      
      return true if criteria.empty? # shortcut to maybe safe performance. XXX remove?
      
      family = criteria.delete(:symbol_family)
      case
      when family == nil
        # nothing to test then
      when family.is_a?(Class)
        if family <= CeSymbol
          return false unless self.is_a?(family)
        else
          raise "invalid argument: :symbol_family => #{family.inspect}"
        end
      when family.is_a?(Array)
        return false unless family.find {|f| self.is_a?(f)}        
      else
        raise "invalid argument: :symbol_family => #{family.inspect}"
      end

      identifier = criteria.delete(:identifier)
      case identifier
      when nil
        # nothing to test then
      when String
        return false unless @identifier == identifier
      when Regexp
        return false unless @identifier =~ identifier
      else
        raise "invalid argument: :identifier => #{identifier.inspect}"
      end

      origin = criteria.delete(:origin)
      #warn "XXXX match #{name_dbg}, origin criterion: #{origin}"
      case origin
      when nil
        # nothing to test then
      when Rocc::CodeElements::CodeElement
        #warn "XXXX match #{name_dbg}.origin: Is #{@origin} == #{origin} ?"
        return false unless @origin == origin
      when Class
        return false unless @origin.is_a? origin
      else
        raise "invalid argument: :origin => #{origin.inspect}"
      end

      conditions = criteria.delete(:conditions)
      case conditions
      when nil
         # nothing to test then
      when Rocc::Semantic::CeCondition
        return false unless @existence_conditions.imply?(conditions)
      else
        raise "invalid argument: :condition => #{condition.inspect}"
      end

      #warn "#{name_dbg} -> match: #{criteria} => true"
      true
    end # def match(criteria)

    private

    def pick_from_hashargs(hashargs, key_symbol)
      raise "Cannot find `#{key_symbol}' in #{hashargs.inspect}" unless hashargs.key? key_symbol # XXX defensive progamming => remove some day
      value = hashargs[key_symbol]
      hashargs.delete(key_symbol) # XXX defensive progamming => remove some day
      value
    end

  end # class CeSymbol

end # module Rocc::Semantic
