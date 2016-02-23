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

module Rocc::Semantic

  class CeSpecification < Rocc::CodeElements::CodeElement

    attr_reader :symbol

    ##
    # +origin+ of a specification shall be an array of those tokens
    # that form this specification. (Note: Child class CeDefinition
    # does it diffenetly and references the implicitly contained
    # declaration's CeDeclaraiton object as its origin.) FIXME use
    # adducers to reference the tokens, use origin for the scope the
    # specification is in.
    #
    # +symbol+ The symbol announced by this specification.
    def initialize(origin, symbol = nil)
      super(origin)
      @symbol = symbol
    end

    # Define a constant containing the string to be given as
    # SPEC_ABBREV to avoid repeated recreation of string object from
    # string literal.
    SPEC_ABBREV = 'Spec'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.spec_abbrev
      SPEC_ABBREV
    end
    
    def name_dbg
      if symbol
        "#{self.class.spec_abbrev}[#{symbol}]"
      else
        "#{self.class.spec_abbrev}[\u2205]"        
      end
    end

    def location
      @origin.first.location
    end

    def symbol=(arg)
      raise if @symbol # XXX(assert)
      @symbol = arg
    end

    def function?
      @symbol.is_a?(CeFunction)
    end

    def variable?
      @symbol.is_a?(CeVariable)
    end

    def type?
      @symbol.is_a?(CeTypedef)
    end

    def macro?
      @symbol.is_a?(CeMacro)
    end

    #def enum?
    #  @symbol.is_a?(CeEnum)
    #end
    #
    #def struct?
    #  @symbol.is_a?(CeStruct)
    #end
    #
    #def union?
    #  @symbol.is_a?(CeUnion)
    #end
    #
    ## returns true if CeSymbol object represents the member of a
    ## struct or union
    #def member?
    #  @symbol.is_a?(CeSUMember)
    #end

  end # class CeSpecification

end # module Rocc::Semantic
