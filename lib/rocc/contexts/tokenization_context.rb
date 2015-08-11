# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  ##
  # ...
  #
  # Not contained in ParsingContext as this context is recreated at each new tokenization method invokation and thus does not need to be ... over multiple method invokations.
  class TokenizationContext

#    attr_reader :compilation_context
    attr_reader :line, :tokens, :remainder, :charpos

    def initialize(line) # compilation_context, 
      # @compilation_context = compilation_context
      @line = line
      @tokens = []
      @remainder = line.text.dup
      @charpos = 0
    end

    ##
    # return true if all tokens have been picked from the context's line, false otherwise
    def finished?
      @remainder.empty?
    end

    ##
    # Return the most recently picked token or nil if no tokens have been picked so far.
    def recent_token
      @tokens.last
    end

    def lstrip
      whitespace = @remainder.slice!(/^\s*/)
      @charpos += whitespace.length
      whitespace
    end

#    def strip
#      lstrip
#      @remainder.rstrip!
#    end

    def pick_comments
      while Tokens::TknComment.pick!(self); end
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
      Tokens::TknPpDirective.pick!(self)
    end
    
    def add_token(tkn)
      @charpos += tkn.text.length + tkn.whitespace_after.length
      @tokens << tkn
    end

  end # class TokenizationContext

end # module Rocc
