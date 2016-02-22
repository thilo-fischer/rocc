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

module Rocc::Semantic

  class CeDeclaration < CeSpecification

    ##
    # +origin+ of a declaration shall be an array of those tokens
    # that form this declaration.
    #
    # +symbol+ is the symbol declared by this function
    def initialize(origin, symbol)
      super
    end

  end # class CeDeclaration

  class CeFunctionDeclaration < CeDeclaration
    attr_reader :param_names
    def initialize(origin, symbol, function_signature)
      super(origin, symbol)
      @param_names = function_signature.params.map {|p| p.name}
      @void = function_signature.is_void?
    end
    # see CeFunctionSignature#is_void?
    def is_void?
      @void
    end
  end # class CeFunctionDeclaration
  
  class CeVariableDeclaration < CeDeclaration; end

end # module Rocc::Semantic
