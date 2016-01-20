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

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented; end

module Rocc::CodeElements::CharRepresented::Tokens

  # forward declarations
  class CeToken          < Rocc::CodeElements::CodeElement; end
  class TknComment       < CeToken; end
  class TknPreprocessor  < CeToken; end
  class TknWord          < CeToken; end
  class TknIntegerLiteral        < CeToken; end
  class TknFloatLiteral        < CeToken; end
  class TknCharLiteral        < CeToken; end
  class TknStringLiteral < CeToken; end
  class Tkn3Char         < CeToken; end
  class Tkn2Char         < CeToken; end
  class Tkn1Char         < CeToken; end

  ##
  # Order in which to test which token is the next.  It is important
  # to test for Tkn3Char before Tkn2Char and for Tkn2Char before
  # Tkn1Char to ensure to detect e.g. the >>= token not as as tokens >
  # and >= or as tokens >, > and =.
  PICKING_ORDER = [ TknWord, TknStringLiteral, TknCharLiteral, TknIntegerLiteral, TknFloatLiteral, TknComment, Tkn3Char, Tkn2Char, Tkn1Char ]

  class CeToken < Rocc::CodeElements::CodeElement
    attr_reader :text, :charpos, :direct_predecessor, :direct_successor, :whitespace_after

    def initialize(origin, text, charpos, whitespace_after = "", direct_predecessor = nil)
      super(origin)
      @text = text
      @charpos = charpos
      @whitespace_after = whitespace_after
      @direct_predecessor = direct_predecessor
      @direct_predecessor.direct_successor = self if @direct_predecessor
    end # initialize

    # FIXME annonce is defined in CodeElement, but is repeatedly being overloaded with no-operation implementations. Consider removing announce from CodeElement base class.
    def announce
      # Don't want to register tokens, they can be referenced from the content of CoLogicLine.
      nil
    end

    ##
    # string to represent this element in rocc debugging and internal error messages
    def name_dbg
      "Tkn[#{@text}]"
    end

    ##
    # string to represent this element in messages from rocc
    def name
      "`#{@text} token"
    end

    ##
    # character(s) to use to separate this element from its origin in path information
    def path_separator
      ":#{@charpos} > "
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
      #warn "reminder: #{tokenization_context.remainder.inspect}"
      #warn "PICKING_REGEXP: #{@PICKING_REGEXP.inspect}"
      #warn "self: #{self.inspect}"
      str = tokenization_context.remainder.slice!(@PICKING_REGEXP)
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
        $log.debug{ "pick `#{str}' from `#{tokenization_context.remainder}'"  }
        raise "deprecated" # XXX handle whitespace_after
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
        whitespace_after = tokenization_context.lstrip!
        $log.debug{ "pick! `#{str}' + `#{whitespace_after}', remainder: `#{tokenization_context.remainder}'" }
        create(tokenization_context, str, whitespace_after)
      end
    end # pick!

    ##
    # Create token of this class from and within the given context.
    def self.create(tokenization_context, text, whitespace_after = "")
      pred = tokenization_context.recent_token
      new_tkn = new(tokenization_context.line, text, tokenization_context.charpos, whitespace_after, pred)
      tokenization_context.add_token(new_tkn)
      $log.debug{ "new token: #{new_tkn.name_dbg}" }
      new_tkn
    end

    ##
    # Token's implementation of CodeElements.pursue.
    def pursue(compilation_context)
      compilation_context.active_branches.each do |b|
        warn "pursue_branch #{b.id} #{name_dbg}" # FIXME loglevel trace ?!
        pursue_branch(compilation_context, b)
      end
    end

    ##
    # Process this token within the given compilation context.
    # Default implementation suitable for all tokens that can't do
    # anything better: Add token to the list of pending tokens.
    # Concrete token classes shall override this method when possible.
    def pursue_branch(compilation_context, branch)
      branch.push_pending(self)
    end

    protected

    #      @ORIGIN_CLASS = CeLogicLine

    def direct_successor=(s)
      @direct_successor = s
    end

    def self.picking_regexp # fixme
      @PICKING_REGEXP
    end

  end # CeToken

end # module Rocc::CodeElements::CharRepresented::Tokens
