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
#require 'rocc/semantic/macro_definition'

module Rocc::Semantic

  class CeMacro < Rocc::CodeElements::CodeElement

    attr_reader :adducer, :identifier, :text, :parameters
    
    ##
    # +origin+ of a +Macro+ is the translation unit it appears in.
    # +adducer+ is the +CeMacroDefinition+ that defines it.
    #
    # +parameters+ is array with parameter names, empty array for
    # function-like macro without parameters, nil for "plain" macros
    def initialize(origin, adducer, identifier, text, parameters = nil)
      super(origin)
      @adducer = adducer
      @identifier = identifier
      @text = text
      @parameters = parameters
    end

    def name_dbg
      '#Macro[@identifier]'
    end

    def is_function_like?
      #@parameters.is_a?(Array)
      @parameters != nil
    end

  end # class CeMacro

end # module Rocc::Semantic
