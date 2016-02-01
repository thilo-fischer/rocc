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
require 'rocc/semantic/macro_expansion'

module Rocc::Semantic

  class CeMacroInvokation < Rocc::CodeElements::CodeElement

    attr_reader :macro, :arguments
    
    ##
    # +origin+ of a +MacroInvokation+ shall be the +TknWord+ token that
    # corresponds to the macro's identifier and thus invokes the
    # macro.
    def initialize(origin, macro)
      super(origin)
      @macro = macro
      if macro.is_function_like?
        @arguments = []
      else
        @arguments = nil
      end
      @opening = @closing = nil
    end

    def name_dbg
      '#MI<#{macro.name_dbg}>'
    end

    def pursue_branch(compilation_context, branch)
      if macro.is_function_like?
        branch.open_token_request(self)
      else
        finalize(compilation_context, branch)
      end
    end  

    def process_token(compilation_context, branch, token)
      # TODO ensure this implements the correct behaviour with ugly macros like
      # #define foo(a, b) ) + (
      # #define bar(a) { a }
      # foo( (1 , 1) )
      # bar( 1 , 2, 3 )
      if @opening
        case token.text
        when ')'
          @closing = token
          branch.close_token_request
          finalize(compilation_context, branch)
        when ','
          @arguments << []
        when "\n" # XXX may only occur if merging
                  # CompilationBrach#open/colse_token_request and
                  # start/stop_collect_macro_tokens and introducing
                  # new specific newline token.
          raise
        else
          @arguments.last << token
        end
      else
        raise unless token.text == '('
        @opening = token
        @arguments << []
      end
    end

    private
    def finalize(compilation_context, branch)
      raise if @macro.is_function_like? and @arguments.count != @macro.parameters.count
      me = CeMacroExpansion.new(self)
      me.pursue_branch(compilation_context, branch)
    end
    
  end # class CeMacroInvokation

end # module Rocc::Semantic
