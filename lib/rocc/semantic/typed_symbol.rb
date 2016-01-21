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

  class TypedSymbol < CeSymbol

    attr_reader :linkage
    
    def initialize(origin, identifier, hashargs)
      @linkage = pick_from_hashargs(hashargs, :linkage)
      @type_specifiers = pick_from_hashargs(hashargs, :type_specifiers) # FIXME not yet processed
      super # XXX defensive progamming => replace some day with # super(origin, identifier)
    end

    def namespace
      :ordinary
    end

    def match(criteria)
      return false unless super
      return true if criteria.empty? # shortcut to maybe safe performance. XXX remove?

      linkage = criteria.delete(:linkage)
      case linkage
      when nil
        # nothing to test then
      when Symbol # note: ruby's Symbol class, not Rocc::Semantic::CeSymbol
        return false unless @linkage == linkage
      when Array
        return false unless linkage.find {|l| @linkage == l}
      else
        raise "invalid argument: :linkage => #{linkage.inspect}"
      end

      true
    end # def match(criteria)
    
  end # class TypedSymbol

end # module Rocc::Semantic
