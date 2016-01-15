# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/code_element'

module Rocc::CodeElements::CharRepresented
  module Tokens

  # forward declarations

  class CoToken          < Rocc::CodeElements::CodeElement; end
  class TknComment       < CoToken;    end
  class TknPreprocessor  < CoToken;    end
  class TknWord          < CoToken;    end
  class TknStringLiteral < CoToken;    end
  class TknNumber        < CoToken;    end
  class Tkn3Char         < CoToken;    end
  class Tkn2Char         < CoToken;    end
  class Tkn1Char         < CoToken;    end

  ##
  # Order in which to test which token is the next.  It is important
  # to test for Tkn3Char before Tkn2Char and for Tkn2Char before
  # Tkn1Char to ensure to detect e.g. the >>= token not as as tokens >
  # and >= or as tokens >, > and =.
  PICKING_ORDER = [ TknWord, TknStringLiteral, TknNumber, TknComment, Tkn3Char, Tkn2Char, Tkn1Char ]

  class CoToken < Rocc::CodeElements::CodeElement
    attr_reader :text, :charpos, :direct_predecessor, :direct_successor

    def initialize(origin, text, charpos, whitespace_after = "", direct_predecessor = nil)
      super(origin)
      @text = text
      @charpos = charpos
      @whitespace_after = whitespace_after
      @direct_predecessor = direct_predecessor
    end # initialize

    # FIXME annonce is defined in CodeElement, but is repeatedly being overloaded with no-operation implementations. Consider removing announce from CodeElement base class.
    def announce
      # Don't want to register tokens, they can be referenced from the content of CoLogicLine.
      nil
    end

    ##
    # string to represent this element in rocc debugging and internal error messages
    def name_dbg
      "Tkn[" + @text + "]"
    end

    ##
    # string to represent this element in messages from rocc
    def name
      "`" + @text + "' token"
    end

    ##
    # character(s) to use to separate this element from its origin in path information
    def path_separator
      ":" + @charpos + " > "
    end

    ##
    # 
    def self.at_front?(str)
      raise "Programming error: This method must be overloaded by deriving classes."
    end
    
    ##
    # Test if the to be tokenized string in tokenization_context
    # begins with a token of this class. If so, return the according
    # section of that string which represents the token; else, return
    # nil.
    def self.peek(tokenization_context)
      at_front?(tokenization_context.remainder)
    end

    
    

    ##
    # If the to be tokenized string in tokenization_context begins with a token of this
    # class, return the according section of that string which
    # represents the token. Else, return nil.
    def self.pick_string(tokenization_context)
      # find regexp in string
      # return part of string matching regexp 
      str = tokenization_context.remainder.slice(@PICKING_REGEXP)
      dbg "found " + path if str
      str
    end # pick_string


    ##
    # If the to be tokenized string in tokenization_context begins with a token of this
    # class, mark the according section of that string which
    # represents the token as tokenized and return that section. Else,
    # return nil.
    def self.pick_string!(tokenization_context)
      # find regexp in string
      # remove part of string matching regexp
      # return part of string matching regexp
      str = tokenization_context.remainder.slice!(@PICKING_REGEXP)
      dbg "found " + path if str
      str
    end # pick_string!

    ##
    # If the to be tokenized string in tokenization_context begins with a token of this
    # class, create and return an instance of this class from that
    # section; does not mark the section as being tokenized.  Else,
    # return nil.
    #
    # If parameter str is given, create and return an instance of this
    # class from that string (ignoring tokenization_context). # FIXME smells ...
    def self.pick(tokenization_context, str = nil)
      str ||= self.pick_string(tokenization_context)
      if str then
        whitespace_after = tokenization_context.lstrip
        create(tokenization_context, str, whitespace_after)
      end

    end # pick

    ##
    # If the to be tokenized string in tokenization_context begins with a token of this
    # class, mark the according section in string as tokenized and
    # create and return an instance of this class from that section.
    # Else, return nil.
    def self.pick!(tokenization_context)
      str = self.pick_string!(tokenization_context)
      if str
        whitespace_after = tokenization_context.lstrip
        create(tokenization_context, str, whitespace_after)
      end
    end # pick!

    ##
    # Create token of this class from and within the given context.
    def self.create(tokenization_context, text, whitespace_after = "")
      pred = tokenization_context.recent_token
      new_tkn = new(tokenization_context.line, text, tokenization_context.charpos, whitespace_after, pred)
      pred.direct_successor = new_tkn if pred
      tokenization_context.add_token(new_tkn)
    end

    ##
    # Token's implementation of CodeElements.pursue.
    def pursue(compilation_context)
      if compilation_context.branches?
        compilation_context.branches.each {|b| pursue(b) }
      else
        pursue_branch(compilation_context)
      end
    end

    ##
    # Process this token within the given compilation context.
    # Default implementation suitable for all tokens that can't do
    # anything better; concrete token classes shall override this
    # method when possible.
    def pursue_branch(compilation_context)
      compilation_context.push_pending(self)
    end

    protected

    #      @ORIGIN_CLASS = CoLogicLine

    def direct_successor=(s)
      @direct_successor = s
    end

    def self.picking_regexp # fixme
      @PICKING_REGEXP
    end

  end # CoToken

  end # module Tokens
end # module Rocc::CodeElements::CharRepresented
