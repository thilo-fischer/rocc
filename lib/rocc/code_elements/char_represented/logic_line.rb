# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish in the
# context of the GPL's copyleft can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/code_elements/code_element'
require 'rocc/code_elements/char_represented/char_object'
require 'rocc/contexts/tokenization_context'

# FIXME rework tokens --> code objects
  
module Rocc::CodeElements::CharRepresented

  ##
  # A CeLogicLine represents a line in a source file after all line
  # endings preceeded with '\' (backslash character) have been
  # removed. A logic line corresponds to one or several successive
  # continued physic lines.
  # 
  # Line numbers always refer to physic lines.
  class CeLogicLine < Rocc::CodeElements::CodeElement

    attr_reader :indentation

    ##
    # Origin is the CePhysicLine or the range of continued
    # CePhysicLines that form this logic line.
    def initialize(origin)
      super(origin)
      @tokens = nil
      @indentation = nil
    end # initialize

    def first_physic_line
      if origin.is_a? Range
        origin.begin
      else
        origin
      end
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "LgLn[#{name}]"
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name
    def name
      if origin.is_a? Range
        "#{origin.begin.line_number}..#{origin.end.line_number}"
      else
        origin.line_number.to_s
      end
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#path_separator
    def path_separator
      ":"
    end
    private :path_separator

    # Skip direct origin (CePhysicLine or Range of) in path. See
    # rdoc-ref:Rocc::CodeElements::CodeElement#path
    def path
      first_physic_line.origin.path + path_separator + name
    end

    # Skip direct origin (CePhysicLine or Range of) in path. See
    # rdoc-ref:Rocc::CodeElements::CodeElement#path_full
    def path_full
      first_physic_line.origin.path_full + path_separator + name
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#location
    #--
    # XXX aliases not listed in rdoc ?!
    # alias location path
    def location; path; end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#pursue
    def pursue(lineread_context)
      log.info{"==> Processing line#{origin.is_a?(Range)?'s':''} #{name} --> `#{Rocc::Helpers::String.str_abbrev_inline(text, 60)}'"}
      track do
        {
          :incident  => :logic_line_pursue,
          :line      => name,
          :content   => text,
        }
      end
      
      cmt_ctx = lineread_context.comment_context
      tokenize(cmt_ctx)
      cc_ctx = cmt_ctx.compilation_context
      super(cc_ctx)
      cc_ctx.finalize_logic_line
    end

    ##
    # The string that makes up this logic line.
    def text
      if origin.is_a?(Range)
        raise "TODO"
      ## merge physical lines
      #if env.remainders.include? self.class
      #  text = env.remainders[self.class].map {|ln| ln.text.sub(/\\$/,"")}.join + text
      #  origin = env.remainders[self.class][0] .. self
      #  env.remainders.delete self.class
      #end
      else
        origin.text
      end
    end

    ##
    # The tokens contained in this logic line.
    def tokens
      raise "#{to_s} has not yet been tokenized." unless @tokens
      @tokens
    end

    alias content tokens

    private

    # TODO move more code from here to TokenizationContext, rename TokenizationContext => Tokenizer
    def tokenize(comment_context)

      tokenization_context = Rocc::Contexts::TokenizationContext.new(comment_context, self)
      
      if tokenization_context.in_multiline_comment?
        # handle ongoing multi line comment
        cmt = tokenization_context.ongoing_multiline_comment
        cmt.pick_more!(tokenization_context)
      else
        # remove leading whitespace
        @indentation = tokenization_context.lstrip!
      end
      
      tokenization_context.pick_pp_directives

      until tokenization_context.finished? do
        picked = CeCharObject.pick!(tokenization_context)
        raise "Could not dertermine next token in `#{tokenization_context.remainder}'" unless picked
      end
      
      # enter multiline comment when parsing `/*'
      if tokenization_context.recent_token and
        tokenization_context.recent_token.is_a? CeCoMultiLineBlockComment
        tokenization_context.announce_multiline_comment(tokenization_context.recent_token)
      end
      
      tokenization_context.terminate

      @tokens = tokenization_context.tokens

    end # tokenize

  end # class CeLogicLine

end # module Rocc::CodeElements::CharRepresented
