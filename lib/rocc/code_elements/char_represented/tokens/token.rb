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

require 'rocc/helpers'
require 'rocc/code_elements/code_element'

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented; end

module Rocc::CodeElements::CharRepresented::Tokens

  # forward declarations
  class CeToken          < Rocc::CodeElements::CodeElement; end
  class TknComment       < CeToken; end
  class TknPreprocessor  < CeToken; end
  class TknWord          < CeToken; end
  class TknLiteral        < CeToken; end
  class TknIntegerLiteral        < TknLiteral; end
  class TknFloatLiteral        < TknLiteral; end
  class TknCharLiteral        < TknLiteral; end
  class TknStringLiteral < TknLiteral; end
  class Tkn3Char         < CeToken; end
  class Tkn2Char         < CeToken; end
  class Tkn1Char         < CeToken; end

  ##
  # Order in which to test which token is the next.  It is important
  # to test for Tkn3Char before Tkn2Char and for Tkn2Char before
  # Tkn1Char to ensure to detect e.g. the >>= token not as as tokens >
  # and >= or as tokens >, > and =.
  PICKING_ORDER = [ TknWord, TknStringLiteral, TknCharLiteral, TknIntegerLiteral, TknFloatLiteral, TknCharLiteral, TknStringLiteral, TknComment, Tkn3Char, Tkn2Char, Tkn1Char ]

  class CeToken < Rocc::CodeElements::CodeElement
    
    attr_reader :text, :charpos, :direct_predecessor, :direct_successor, :whitespace_after

    ##
    # +origin+ is the logic line this token is located in.
    #
    # +text+ is the string representing this token.
    #
    # +charpos+ is the index of the first character of the token in
    # +origin.text+.
    # 
    # +whitespace_after+ is the whitespace found after this token that
    # splits this token from the successive token.
    #
    # +direct_predecessor+ is the token that is directly before this
    # token.
    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super(origin)
      @text = text
      @charpos = charpos
      @whitespace_after = whitespace_after
      @direct_predecessor = direct_predecessor
      @direct_predecessor.direct_successor = self if @direct_predecessor
    end # initialize

    def family_abbrev
      'Tkn'
    end
    
    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "#{family_abbrev}[#{Rocc::Helpers::String::abbrev(Rocc::Helpers::String::no_lbreak(@text))}]"
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name
    def name
      @text
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#path_separator
    def path_separator
      ":#{@charpos} > "
    end
    
    # See rdoc-ref:Rocc::CodeElements::CodeElement#location
    #--
    # XXX aliases not listed in rdoc ?!
    # alias location path
    def location; path; end

    ##
    # for Tokens, adducer and origin are (usually) the same
    alias adducer origin
    
    ##
    # If the to be tokenized string in tokenization_context begins
    # with a token of this class, mark the according section of that
    # string which represents the token as tokenized and return that
    # section. Else, return nil.
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
    # If the to be tokenized string in tokenization_context begins
    # with a token of this class, mark the according section in string
    # as tokenized and create and return an instance of this class
    # from that section.  Else, return nil.
    def self.pick!(tokenization_context)
      str = self.pick_string!(tokenization_context)
      if str
        whitespace_after = pick_whitespace!(tokenization_context)
        $log.debug{ "pick! `#{str}' + `#{Rocc::Helpers::String::no_lbreak(whitespace_after)}', remainder: `#{tokenization_context.remainder}'" }
        create(tokenization_context, str, whitespace_after)
      end
    end # pick!

    def self.pick_whitespace!(tokenization_context)
      whitespace = tokenization_context.lstrip! || ''
      whitespace += "\n" if tokenization_context.finished?
      whitespace
    end
    # XXX private :pick_whitespace!

    ##
    # Create token of this class from and within the given context.
    def self.create(tokenization_context, text, whitespace_after = '')
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
        if b.collect_macro_tokens?
          b.greedy_macro.add_token(self)
        elsif b.has_token_request?
          b.token_requester.process_token(compilation_context, b, self)
        else
          warn "#{name_dbg}.pursue_branch #{b.id} (#{path_dbg})\n`- #{b.scope_stack_trace}" # FIXME loglevel trace ?!
          pursue_branch(compilation_context, b)
        end
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

    ##
    # Test if +str+ begins with a token of this class. If so, return
    # the according section of that string which represents the token;
    # else, return nil.
    #
    # XXX seems not in use => deprecated?
    def self.at_front?(str)
      raise "Programming error: This method must be overloaded by deriving classes."
    end
    
    ##
    # Test if the to be tokenized string in tokenization_context
    # begins with a token of this class. If so, return the according
    # section of that string which represents the token; else, return
    # nil.
    #
    # XXX seems not in use => deprecated?
    def self.peek(tokenization_context)
      at_front?(tokenization_context.remainder)
    end

    ##
    # Conditions that must apply for this token to be part of the code
    # after preprocessing.
    def conditions
      0 # FIXME
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
