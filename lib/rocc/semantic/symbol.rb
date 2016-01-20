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

  class Symbol < Rocc::CodeElements::CodeElement

    attr_reader :adducers

    # origin is the unit the symbol lives in, e.g. the translation
    # unit it belongs to.  identifier is the symbols name.
    def initialize(origin, identifier, hashargs)
      raise unless hashargs.empty? # XXX defensive progamming => remove some day
      super(origin)
      @identifier = identifier
      @adducers = []
    end # initialize

    # adducers are the specifications that announce the symbol
    def add_adducer(a)
      @adducers << a
    end

    alias adducer adducers

    private

    def pick_from_hashargs(hashargs, key_symbol)
      raise unless hashargs.key? key_symbol # XXX defensive progamming => remove some day
      value = hashargs[key_symbol]
      hashargs.delete(key_symbol) # XXX defensive progamming => remove some day
      value
    end

  end # class Symbol

end # module Rocc::Semantic
