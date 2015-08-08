# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  class TokenizationContext

#    attr_reader :compilation_context
    attr_reader :tokens, :remainder, :charpos

    def initialize(line_text) # compilation_context, 
#      @compilation_context = compilation_context
      @tokens = []
      @remainder = line_text.dup
      @charpos = 0
    end

    def finished?
      @remainder.empty?
    end

    def recent_token
      @tokens.last
    end

    def lstrip
      @charpos += @remainder.slice!(/^\s*/).length
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
      tkn = Tokens::TknPpDirective.pick!(env)
      @tokens << tkn if tkn
    end
    
    def progress_token(tkn = nil, length)
      @recent_token = tkn if tkn
      @line_offset += length
      @line_offset += @remainder.slice!(/^\s*/).length
      @recent_token
    end

  end # class TokenizationContext

end # module Rocc
