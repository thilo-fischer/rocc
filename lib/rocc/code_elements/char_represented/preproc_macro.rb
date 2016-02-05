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

require 'rocc/semantic/macro'
require 'rocc/semantic/macro_definition'

module Rocc::CodeElements::CharRepresented

  class CeCoPpDefine < CeCoPpDirective
    # TODO the stuff picked here is more than a token, it is several tokens at once. same applies to (most of) the other preprocessor "token" classes handling preprocessor directives. technically fine, but calling it a token is missleading.
    @REGEXP = /#\s*define\s*?(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*?(?<identifier>[A-Za-z_]\w*)(?<parameters>\(.*?\))?/

    attr_reader :identifier, :comments, :parameters

    public # FIXME protect from write access from other classes, but allow write access from class methods
    #protected
    attr_writer :identifier, :comments, :parameters

    public

    # XXX_R mostly redundant to CeCoPpInclude.pick!
    def self.pick!(tokenization_context)

      tkn = super

      if tkn
        # TODO_F(pick_captures)
        tkn.text =~ picker.picking_regexp

        tkn.identifier = $~[:identifier]
        
        comments   = $~[:comments]
        parameters = $~[:parameters]

        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `define' and macro identifier
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        # FIXME create comment objects
        #while not comments.strip!.empty? do
        #  CeCoComment.pick!(tokenization_context, comments)
        #end
        
        tkn.parameters = if parameters
                           parameters[ 0] = ""
                           parameters[-1] = ""
                           parameters.split(/\s*,\s*/)
                         end
      end

      tkn
    end # pick!


    def pursue(compilation_context)
      m_def = Rocc::Semantic::CeMacroDefinition.new(self)
      macro = Rocc::Semantic::CeMacro.new(compilation_context.translation_unit, m_def, @identifier, @parameters)
      compilation_context.announce_symbol(macro)
      compilation_context.open_token_request(macro)
    end # pursue_branch

    def tokens
      # XXX_F room for improvement
      line_tokens = origin(LogicLine).tokens
      own_index = line_tokens.index(self)
      line_tokens[own_index+1..-1]
    end

  end # class CeCoPpDefine

  class CeCoPpUndef < CeCoPpDirective
    @REGEXP = /^#\s*undef\s+/

    def pursue(compilation_context)
      #raise "invalid syntax" unless successor.is_a? TknWord # fixme: provide appropriate exception
      
      # TODO_W Add a CeMacroUndef object to the affected
      # macro(s). Ensure macro symbols will be used only at those
      # lines in between the CeMacroDefinition and CeMacroUndef of
      # that macro.
      raise "not yet supported"
    end # pursue_branch

  end # class CeCoPpUndef

end # module Rocc::CodeElements::CharRepresented::Tokens
