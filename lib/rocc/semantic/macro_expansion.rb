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
require 'rocc/code_elements/char_represented/char_object' # TODO_R(pickers) `require 'rocc/code_elements/char_represented/tokens/misc_tokens'' would be sufficient if only misc_tokens.rb would not depend on char_object.rb and vice versa (because TknWord < CeCoToken < CodeObject and CodeObject references CeCoToken)

module Rocc::Semantic

  class CeMacroExpansion < Rocc::CodeElements::CodeElement

    ##
    # +origin+ of a +MacroExpansion+ shall be the according
    # +CeMacroInvokation+.
    def initialize(origin)
      super
      finalize
    end

    alias invokation origin
    
    def macro
      invokation.macro
    end
    
    def pursue_branch(compilation_context, branch)
      @tokens.each {|tkn| tkn.pursue_branch(compilation_context, branch)}
    end
    
    def name_dbg
      '#MX<#{invokation.macro.name_dbg}>'
    end
    
    private
    def finalize
      @tokens = macro.tokens.dup
      # FIXME adapt origin # @tokens.each {|t| t.origin = self}
      @tokens.each_with_index do |t, tkn_idx|
        if t.is_a? Rocc::CodeElements::CharRepresented::Tokens::TknWord
          param_idx = macro.parameters.index(t.text)
          if param_idx
            @tokens[tkn_idx] = invokation.arguments[param_idx]
          end
        end
      end
      @tokens.flatten!
    end

  end # class CeMacroExpansion

end # module Rocc::Semantic
