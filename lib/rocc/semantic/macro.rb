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
#require 'rocc/semantic/macro_definition'

module Rocc::Semantic

  class CeMacro < Rocc::Semantic::CeSymbol

    attr_reader :adducer, :tokens, :parameters
    
    ##
    # +origin+ of a +Macro+ is the translation unit it appears in.
    # +adducer+ is the +CeMacroDefinition+ that defines it.
    #
    # +parameters+ is array with parameter names, empty array for
    # function-like macro without parameters, nil for "plain" macros
    def initialize(origin, identifier, excond, parameters = nil)
      super(origin, identifier, excond, {})
      @parameters = parameters
      @tokens = []
      log.debug{"new macro #{self}, parameters: #{@parameters.inspect}"}
    end

    alias translation_unit origin
    alias definition adducer
    
    def name
      "macro `#{@identifier}'"
    end
    
    def name_dbg
      "#M[#{@identifier}]"
    end

    # FIXME? define constant instead of function?
    def self.family
      :macro
    end
    def self.family_character
      'm'
    end

    def namespace
      :macro
    end

    def is_function_like?
      #@parameters.is_a?(Array)
      @parameters != nil
    end

    def process_token(compilation_context, arg)      
      @tokens << arg
      log.debug{"#{self}.tokens: #{@tokens}"}
    end

  end # class CeMacro

end # module Rocc::Semantic
