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
require 'rocc/semantic/specification'
require 'rocc/semantic/declaration'

module Rocc::Semantic

  class CeDefinition < CeSpecification

    attr_reader :body

    ##
    # +declaration+ A definition always implies a declaration (in
    # C/C++ code). If a definition is found, the definition shall be
    # addad to the symbols adducers. The definition than holds a
    # reference to the declaration implied by the represented
    # definition. (CeDefinition could also derive from CeDeclaration,
    # but due to the "prefer aggregation over inheritence" principle,
    # it is implemeted like this.)
    #
    # CeDefinition#origin is the contained declaration.
    def initialize(declaration)
      super(declaration)
      @body = nil
    end

    alias declaration origin

    def adducer
      declaration.adducer + body.adducer
    end

    ##
    # For function definitions, +body+ is the compound statement
    # implementing the function (aka the function body). A function
    # definition will always have a +body != nil+. For variable
    # definitons, +body+ is the variable's initializer if specified,
    # nil otherwise.
    #
    # Even if a function has different implementations or a variable has different initializers in different preprocessor branches, a definition will always have at most one body:
    #
    # * If there are several blocks given for a function in separate
    #   preprocessor branches (as in the following code example), this
    #   will result in the CeFunction object referencing multiple
    #   CeDefinition objects with different existance conditions.
    #   
    #   E.g.
    #    int foo()
    #    #ifdef BRANCH0
    #      { return 0; }
    #    #else
    #      { return 42; }
    #    #endif
    #
    # * If there is a block given for a function that deviates in
    #   different preprocessor branches (as in the following code
    #   example), this will result in the CeFunction object
    #   referencing a CeDefinition object with a CeCompoundStatement
    #   +body+ in which some statements and expressions have different
    #   existance conditions.
    #   
    #   E.g.
    #    int foo() {
    #    #ifdef BRANCH0
    #      return 0;
    #    #else
    #      return 42;
    #    #endif
    #    }
    #
    # * The same applies for variable definitions with expressions
    #   instead of compound statements.
    def body=(arg)
      raise if @body # XXX(assert)
      @body = arg
    end

    def complete?
      @body
    end

    def finalize
      raise "definition without body" unless complete?
      declaration.symbol.add_definition(self)
      self
    end

    def symbol
      declaration.symbol
    end

  end # class CeDefinition

  class CeFunctionDefinition < CeDefinition; end
  class CeVariableDefinition < CeDefinition; end

end # module Rocc::Semantic
