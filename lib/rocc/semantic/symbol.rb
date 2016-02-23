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

require 'rocc/code_elements/code_element'

module Rocc::Semantic

  class CeSymbol < Rocc::CodeElements::CodeElement

    attr_reader :identifier, :existence_conditions, :pure_declarations, :definitions

    # origin is the unit the symbol lives in, e.g. the translation
    # unit it belongs to.  identifier is the symbols name.
    def initialize(origin, identifier, conditions, hashargs)
      raise "unprocessed hashargs: #{hashargs.inspect}" unless hashargs.empty? # XXX defensive progamming => remove some day
      super(origin)
      @pure_declarations = []
      @definitions = []
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

    def adducer
      @pure_declarations + @definitions
    end

    def all_declarations
      @pure_declarations + @definitions.map {|d| d.declaration}
    end

    ##
    # Return the symbol's declaration that seems most relevant: If the
    # symbol is a variable and the variable has an intializing
    # definition, return the declaration implied by that
    # definition. Otherwise, if the symbol has a definition, return
    # the declaration implied by that definition. Otherwise, return
    # the symbol's declaration. If multipe definitions or declarations
    # exist with different existence conditions, consider the one with
    # the most probable existence conditions. (If several have
    # distinct existence conditions with same probability, an
    # arbitrary one of these is chosen.) If multiple declaritions
    # with identical existence condititons exist, return an arbitrary
    # one of these.
    #
    #--
    # XXX If multiple declaritions with identical existence
    # condititons exist, return a specific one.
    def significant_declaration
      if @definitions.empty?
        #if @pure_declarations.length > 1
        #  @pure_declarations.first # TODO_W determine and return the "most significant" declaration
        #else
        #  @pure_declarations.first
        #end
        @pure_declarations.max_by {|d| d.existence_conditions.probability }
      else
        #if @definitions.length > 1
        #  @definitions.first # TODO_W determine and return the "most significant" definition
        #else
        #  @definitions.first
        #end
         @definitions.max_by {|d| d.existence_conditions.probability }
     end        
    end
    
    def ==(other)
      self.class == other.class and
        @origin == other.origin and
        @identifier == other.identifier
    end

    def add_declaration(arg)
      @pure_declarations << arg
    end

    def add_definition(arg)
      already_defined = @definitions.find do |d|
        d.existence_conditions.imply?(arg.existence_conditions) or
          arg.existence_conditions.imply?(d.existence_conditions)
      end
      raise "double defined symbol: #{arg} found at #{arg.location}, but already defined at #{already_defined.location}" if already_defined
      raise "programming error :(" if @pure_declarations.include?(arg.declaration) # XXX(assert)
      @definitions << arg
    end
    
    def existence_probability
      existence_conditions.probability
    end

    def implicit_existence_conditions
      inject_start = (@pure_declarations + @definitions).first.existence_conditions # XXX works, but smells
      (@pure_declarations + @definitions).inject(inject_start) do |conds, spec|
        conds.disjunction(spec.existence_conditions)
      end
    end
    private :implicit_existence_conditions

    def assert_existence_conditions_consistency
      raise "inconsisten existence conditions" unless existence_conditions.equivalent?(implicit_existence_conditions)
    end
    private :assert_existence_conditions_consistency

    # Return true if the symbol matches the given criteria. +criteria+
    # is a hash that may contain the keys listed in the following that
    # map to Symbols (Ruby Symbols, not CeSymbol), Strings or child
    # classes of CeSymbol or to Arrays of such. If the key maps to an
    # array, than the symbol must match (at least) one of the array
    # entries for the +match+ method to return true.
    # 
    # [+:family+] Specifies whether the symbol shall be a
    #   variable/function/macro/typedef/... . Argument shall be the
    #   according subclass of CeSymbol corresponding to the
    #   appropriate familiy.
    #
    # [+:linkage] Specifies the desired linkage of the symbol if
    #   applicable (elements from some families don't have any
    #   linkage).
    #
    # [+:conditions] Specifies the conditions to be assumed for
    #   preprocessor conditionals (+existence_conditions+ of the
    #   symbol).
    #
     def match(criteria)
      #warn "XXXX #{name_dbg} -> match: #{criteria}"
      
      return true if criteria.empty? # shortcut to maybe safe some performance. XXX remove?
      
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
