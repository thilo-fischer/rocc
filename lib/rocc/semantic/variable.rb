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

  class CeVariable < CeTypedSymbol

   def initialize(origin, identifier, conditions, hashargs)
     super
     @initialize_defs = nil
   end
   
   def self.default_linkage
     :extern
   end
   
   def name
     "variable `#{@identifier}'"
   end
   
   def name_dbg
     "Var[#{@identifier}]"
   end
   
   # FIXME? define constant instead of function?
   def self.family
     :variable
   end
   def self.family_character
     'v'
   end
   
    ##
    # +initialize_defs+ variable definitions that initilize the
    # variable.
   def initialize_defs
    @initialize_defs ||= @definitions.select {|d| d.initializer?}
   end

   def add_definition(arg)
     # invalidate @initialize_defs cache as new definition might be a
     # def with initializer
     @initialize_defs = nil
     # (Tracking a list of definitions with initializers with
     #@initialize_defs += arg if arg.initializer?
     # here won't work because definitions don't know yet whether
     # they are with or without initializers when being added.
     # FIXME(initializers) add a specific class CeVarDefInit < CeVariableDefinition for variable definitions with initializers and construct objects of that class when creating definitions at '=' tokens, use CeVariableDefinition when creating definitions at ';' and ',' tokens.
     super
   end
   
   def significant_declaration
     if initialize_defs.empty?
       super
     else
       initialize_defs.max_by {|d| d.existence_conditions.probability }
     end
   end

   def check_double_symbol(arg)
     # FIXME(initializers) Check for double variable initializations
     #already_initialized = initialize_defs.find do |d|
     #  d.existence_conditions.imply?(arg.existence_conditions) or
     #    arg.existence_conditions.imply?(d.existence_conditions)
     #end
     #if already_defined
     #  warn "arg[#{arg}]@#{arg.existence_conditions.inspect}(#{arg.existence_conditions}) #{already_defined.existence_conditions.imply?(arg.existence_conditions)?'<':''}==#{arg.existence_conditions.imply?(already_defined.existence_conditions)?'>':''} already_defined[#{already_defined}]@#{already_defined.existence_conditions.inspect}(#{already_defined.existence_conditions})"
     #  raise "doubly defined symbol: #{arg} found at #{arg.location}, but already defined at #{already_defined.location}"
     #end
   end
   private :check_double_symbol
    
  end # class CeVariable

end # module Rocc::Semantic
