# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/helpers'

module Rocc::Contexts

  ##
  # ...
  #
  # Not contained in ParsingContext as this context is recreated at each new tokenization method invokation and thus does not need to be ... over multiple method invokations.
  class TokenizationContext

    attr_reader :line, :tokens, :remainder, :charpos

    def initialize(comment_context, line)
      @comment_context = comment_context
      @line = line
      @tokens = []
      @remainder = line.text.dup
      @charpos = 0
    end

    ##
    # return true if all tokens have been picked from the context's line, false otherwise
    def finished?
      #$log.debug{ "TokenizationContext.finished? => #{@remainder.empty?}, remainder: `#{@remainder}'" }
      #$log.debug{ Rocc::Helpers.backtrace(8) }
      @remainder.empty?
    end

    def terminate
      # FIXME find something better to do than raise that string ...
      raise "not completed" unless finished?
    end
    
    ##
    # Return the most recently picked token or nil if no tokens have been picked so far.
    def recent_token
      @tokens.last
    end

    def lstrip!
      whitespace = @remainder.slice!(/^\s*/)
      @charpos += whitespace.length
      whitespace
    end

#    def strip
#      lstrip
#      @remainder.rstrip!
#    end

    def pick_comments
      while Rocc::CodeElements::CharRepresented::Tokens::TknComment.pick!(self); end
    end
    
    def pick_pp_directives
      # handle comments interfering with preprocessor directives
      pick_comments
      if @remainder[0] == "#" then
        @remainder[0] = ""
        lstrip
        pick_comments
        @remainder.prepend "#"
      end

      # handle preprocessor directives
      Rocc::CodeElements::CharRepresented::Tokens::TknPpDirective.pick!(self)
    end
    
    def add_token(tkn)
      @charpos += tkn.text.length + tkn.whitespace_after.length
      @tokens << tkn
    end

    def in_multiline_comment?
      not @comment_context.completed?
    end

    def announce_multiline_comment(comment)
      @comment_context.announce_multiline_comment(comment)
    end

    # FIXME rename leave => end (?)
    def leave_multiline_comment
      @comment_context.leave_multiline_comment
    end


  end # class TokenizationContext

end # module Rocc
