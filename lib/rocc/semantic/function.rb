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

require 'rocc/semantic/typed_symbol'

module Rocc::Semantic

  class CeFunction < TypedSymbol

    attr_reader :parameters

    def initialize(origin, identifier, hashargs)
      super
      @parameters = []
      @param_list_complete = false
    end

    def self.default_linkage
      :extern
    end

    def variadic?
      (not @parameters.empty?) and @parameters.last.variadic?
    end

    def announce_parameter(position, type)
      raise if  param_list_complete?
      # assume all parameters are added in their native order
      raise unless @parameters.count == position - 1
      # TODO @parameters << CeFunctionParameter.new(self, type)
    end

    def param_list_complete?
      @param_list_complete
    end

    def param_list_finalize
      @param_list_complete = true
    end
    
    def name
      "function `#{@identifier}'"
    end
    
    def name_dbg
      "Fkt[#{@identifier}]"
    end

  end # class CeFunction

end # module Rocc::Semantic
