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

require 'rocc/semantic/typed_symbol'

module Rocc::Semantic

  class CeFunction < CeTypedSymbol

    attr_reader :parameters, :signatures, :block

    def initialize(origin, identifier, conditions, hashargs)
      parameters = pick_from_hashargs(hashargs, :parameters)
      super
      @parameters = []
      @param_list_complete = false
      @signatures = []
      @block = nil
      parameters.params.each_with_index {|p,i| announce_parameter(i+1, p.type, p.storage_class_specifier)} # FIXME_R quickfix
    end

    def self.default_linkage
      :extern
    end

    def variadic?
      (not @parameters.empty?) and @parameters.last.variadic?
    end

    # +position+ number corresponding to the position of the parameter. First parameter has position 0, second parameter position 1, and so on.
    def announce_parameter(position, type, storage_class)
      if param_list_complete?
        raise unless position < @parameters.count
        # TODO raise unless @parameters[position].type == type and @parameters[position].storage_class == storage_class
      else
        # assume all parameters are added in their native order
        raise unless @parameters.count == position - 1
        @parameters << :function_parameter # FIXME
        # TODO @parameters << CeFunctionParameter.new(self, type)
      end
    end

    def param_list_complete?
      @param_list_complete
    end

    def param_list_finalize
      @param_list_complete = true
    end

    def complete?
      param_list_complete?
      # XXX function definition also requires a block/compound statement
    end

    def add_signature(arg)
      @signatures << arg
    end

    def block=(arg)
      #warn "*** assign block #{arg.name_dbg} to #{name_dbg} (current: #{@block.inspect})"
      if @block
        if @block.existence_conditions.equivalent?(arg.existence_conditions)
          warn "XX block #{@block.existence_conditions} #{@block.existence_conditions.class}"
          warn "XX arg   #{arg.existence_conditions} #{arg.existence_conditions.class}"
          raise "multiple definitions for #{path_dbg}" if @block
        else
          @block = [ @block, arg ] # FIXME smells
        end
      else
        @block = arg
      end
    end
    
    def name
      "function `#{@identifier}'"
    end
    
    def name_dbg
      "Fkt[#{@identifier}]"
    end

    # FIXME? define constant instead of function?
    def self.family
      :function
    end
    def self.family_character
      'F'
    end
  end # class CeFunction

end # module Rocc::Semantic
