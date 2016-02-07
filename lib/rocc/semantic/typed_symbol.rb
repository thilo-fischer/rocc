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

require 'rocc/semantic/symbol'

module Rocc::Semantic

  class CeTypedSymbol < CeSymbol

    attr_reader :linkage
    
    def initialize(origin, identifier, conditions, hashargs)
      @linkage = pick_from_hashargs(hashargs, :linkage)
      @type_specifiers = pick_from_hashargs(hashargs, :type_specifiers) # FIXME not yet processed
      if hashargs.key?(:type_qualifiers)
        @type_qualifiers = pick_from_hashargs(hashargs, :type_qualifiers) # FIXME not yet processed
      end
      if hashargs.key?(:storage_class)
        @storage_class = pick_from_hashargs(hashargs, :storage_class) # FIXME not yet processed
      end
      super # XXX defensive progamming => replace some day with # super(origin, conditions, identifier)
      @adducers = []
    end

    def name_dbg
      "TySym[#{@identifier}]"
    end    

    # adducers are the specifications that announce the symbol
    def add_adducer(a)
      @adducers << a
    end

    alias adducer adducers

    def namespace
      :ordinary
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
