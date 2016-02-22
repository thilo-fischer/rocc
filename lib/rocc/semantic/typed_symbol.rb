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

require 'rocc/semantic/symbol'

module Rocc::Semantic

  class CeTypedSymbol < CeSymbol

    attr_reader :type_specifiers, :type_qualifiers, :storage_class, :linkage
    
    def initialize(origin, identifier, conditions, hashargs)

      @type_specifiers = pick_from_hashargs(hashargs, :type_specifiers) # FIXME not yet processed
      
      if hashargs.key?(:type_qualifiers)
        @type_qualifiers = pick_from_hashargs(hashargs, :type_qualifiers) # FIXME not yet processed
      end

      if hashargs.key?(:storage_class)
        @storage_class = pick_from_hashargs(hashargs, :storage_class) # FIXME not yet processed
      end

      super # XXX defensive progamming => replace some day with # super(origin, conditions, identifier)

      # XXX Check: linkage might not apply to all symbols derived from CeTypedSymbol (CeSUMember, CeTypedef, ..?), there might be classes not derived from CeTypedSymbol where linkage applies (CeEnum, CeSymbolCompound, ..?). => If so: Add another level to inheritence hierarchy or extract linkage stuff to mixin?
      if descend_origin(Rocc::Semantic::CeFunctionDefinition)
        @linkage = :none
      else
        case @storage_class
        when nil
          @linkage = self.class.default_linkage # XXX necessary to query symbol_familiy or is it always :extern anyway?          
        when :typedef
          raise "not yet supported" # FIXME
        when :static
          @linkage = :intern
        when :extern
          @linkage = :extern # XXX what about function local symbols declared with storage class specifier extern ?
        end
      end

    end

    def name_dbg
      "TySym[#{@identifier}]"
    end    

    def namespace
      :ordinary
    end

    def ==(other)
      super and
        @type_specifiers == other.type_specifiers and
        @linkage == other.linkage and
        @type_qualifiers == other.type_qualifiers and
        (
          @storage_class == other.storage_class or
          false # TODO_W allow compatible storage class specifiers
        )
    end

    def match(criteria)
      return false unless super
      return true if criteria.empty? # shortcut to maybe safe performance. XXX remove?

      linkage_criterion = criteria.delete(:linkage)
      case linkage_criterion
      when nil
        # nothing to test then
      when Symbol # note: ruby's Symbol class, not Rocc::Semantic::CeSymbol
        return false unless @linkage == linkage_criterion
      when Array
        return false unless linkage_criterion.find {|l| @linkage == l}
      else
        raise "invalid argument: :linkage => #{linkage_criterion.inspect}"
      end

      true
    end # def match(criteria)
    
  end # class CeTypedSymbol

end # module Rocc::Semantic
