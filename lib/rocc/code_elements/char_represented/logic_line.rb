# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeObjects

  require 'rocc/code_objects/code_object'

  # forward declarations
  class CoFile < CodeObject; end

  require 'rocc/code_objects/tokens/tokens'
  
  
  class CoLogicLine < CodeObject
    attr_reader :indentation

    def initialize(origin)
      super(origin)
      @tokens = nil
      @indentation = nil
    end # initialize

    def text
      if origin.class == Range
        raise "TODO"
#        # merge physical lines
#        if env.remainders.include? self.class
#          text = env.remainders[self.class].map {|ln| ln.text.sub(/\\$/,"")}.join + text
#          origin = env.remainders[self.class][0] .. self
#          env.remainders.delete self.class
#        end
      else
        origin.text
      end
    end

    def announce
      # Don't want to register lines, they can be referenced from the content of ... are they? (fixme)
      nil
    end

    def pursue(context)
      tokenize(context).map {|t| t.pursue(context.compilation_context)}      
    end

    def tokens
      raise "#{to_s} has not yet been tokenized." unless @tokens
      @tokens
    end

    alias content tokens

    private

    # TODO move more code from here to TokenizationContext, rename TokenizationContext => Tokenizer
    def tokenize(lr_ctx)

      tkn_ctx = TokenizationContext.new(self) # lx_ctx.cc_ctx, 

      if lr_ctx.multiline_comment
        # handle ongoing multi line comment
        Tokens::TknMultiLineBlockComment.pick!(tkn_ctx)
        lr_ctx.leave_multiline_comment if tkn_ctx.recent_token.complete?
      else
        # remove leading whitespace
        @indentation = tkn_ctx.lstrip
      end
      
      tkn_ctx.pick_pp_directives

      until tkn_ctx.finished? do
        unless Tokens::CoToken::PICKING_ORDER.find {|c| c.pick!(tkn_ctx)}
          raise "Could not dertermine next token in `#{remainder}'"
        end
      end

      if tkn_ctx.recent_token and
        tkn_ctx.recent_token.class.is_a? Tokens::TknMultiLineBlockComment and
        not tkn_ctx.recent_token.complete?
        lr_ctx.announce_multiline_comment(tkn_ctx.recent_token)
      end
        
      @tokens

    end # tokenize

  end # class CoLogicLine

end # module Rocc::CodeObjects
