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
    # CeDefinition#origin is the contained declaration (in deviance to
    # CeSpecification's meaning of origin). FIXME use origin and
    # adducers in CeSpecification and its other child classes as in
    # CeDefinition, use origin for the scope the specification is in.
    def initialize(declaration)
      super(declaration)
      @body = nil
    end

    # Define a constant containing the string to be given as
    # SPEC_ABBREV to avoid repeated recreation of string object from
    # string literal.
    SPEC_ABBREV = 'Def'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.spec_abbrev
      SPEC_ABBREV
    end
    
    alias declaration origin

    def location
      declaration.location
    end

    def adducer
      if body
        declaration.adducer + body.adducer
      else
        declaration.adducer
      end
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

    def finalize
      #declaration.symbol.add_definition(self)
      self
    end

    def symbol
      declaration.symbol
    end

  end # class CeDefinition

  class CeFunctionDefinition < CeDefinition
    def finalize
      raise "definition without body" unless @body
      super
    end
  end
  
  class CeVariableDefinition < CeDefinition
    def initializer?
      @body
    end
  end

  ##
  # Handles macro definitions analogue to other definitions.  The
  # CeCoPpDefine object of the preprocessor directive defining the
  # macro is considered the macros declaration. The CeCoPpDefine
  # object encapsulates the +#define+ token, the macros indentifier
  # and the macros parameter list (if given). As such, the macro
  # definition consists of a CeCoPpDefine object and a +body+ of those
  # tokens that make up the replacement text of the macro.
  class CeMacroDefinition < CeDefinition
    attr_reader :symbol
    def initialize(declaration, symbol)
      super(declaration)
      @symbol = symbol
    end
    # Define a constant containing the string to be given as
    # SPEC_ABBREV to avoid repeated recreation of string object from
    # string literal.
    SPEC_ABBREV = '#def'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.spec_abbrev
      SPEC_ABBREV
    end
    alias define_directive origin
    def existence_conditions
      declaration.existence_conditions
    end
  end

end # module Rocc::Semantic
