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

require 'rocc/code_elements/char_represented/tokens/token'

module Rocc::CodeElements::CharRepresented::Tokens

  class TknComment < CeToken; end

  class TknLineComment < TknComment
    # from // to end of line
    @PICKING_REGEXP = /^\/\/.*$/
    def family_abbrev
      "TknLCmt"
    end
  end # class TknLineComment
  
  class TknBlockComment < TknComment
    # from /* to the next (non-greedy) */
    @PICKING_REGEXP = /^\/\*.*?\*\//
    def family_abbrev
      "TknBCmt"
    end
  end # class TknBlockComment

  # XXX unclean. (Not a token => shouldn't be subclass of CeToken.)
  class TknMultiLineBlockCommentEnd < CeToken
    @PICKING_REGEXP = /^.*?\*\//
    def family_abbrev
      "TknMlCmtEnd"
    end
  end # class TknMultiLineBlockCommentEnd

  # XXX rename MultiLine => Multiline
  class TknMultiLineBlockComment < TknBlockComment
    @PICKING_REGEXP = /^\/\*.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super([origin], text + whitespace_after, charpos, '', direct_predecessor)
    end

    def self.create(tokenization_context, text, whitespace_after = '')
      cmt = super
      tokenization_context.announce_multiline_comment(cmt)
      cmt
    end

    ##
    # Same as CeToken.pick!, but not as a class method that creates an
    # according class instance when token is found, as an instance
    # method to be invoked on a class instance to extend the instance
    # with matching code sections.
    def pick_more!(tokenization_context)
      @origin << tokenization_context.line
      str = TknMultiLineBlockCommentEnd.pick_string!(tokenization_context)
      if str
        tokenization_context.leave_multiline_comment
        @text += str
        @whitespace_after = self.class.pick_whitespace!(tokenization_context)
        $log.debug{ "picked `#{name_dbg}' + `#{Rocc::Helpers::String::no_lbreak(@whitespace_after)}', remainder: `#{tokenization_context.remainder}'" }
      else
        @text += tokenization_context.remainder
        tokenization_context.remainder.clear
      end
    end # pick_more!

    def family_abbrev
      "TknMlCmt"
    end
  end # class TknMultiLineBlockComment

  class TknComment < CeToken

    THIS_CLASS = TknComment
    SUBCLASSES = [ TknLineComment, TknBlockComment, TknMultiLineBlockComment ]
    #@PICKING_REGEXP = /^(\/\/.*$|\/\*.*?(\*\/|$))/

    ABBREV_CHARCNT = 8

    def self.pick!(tokenization_context)
      if self != THIS_CLASS
        # allow subclasses to call superclass' method implementation
        super
      else
        tkn = nil
        SUBCLASSES.find {|c| tkn = c.pick!(tokenization_context)}
        tkn
      end
    end   
    
    def pursue_branch(compilation_context, branch)
      nil
    end

    def family_abbrev
      "TknCmt"
    end

    def text_abbrev
      if text.length < ABBREV_CHARCNT + 2
        @text
      else
        @text[0..ABBREV_CHARCNT] + '...'
      end
    end
    
  end # class TknComment

end # module Rocc::CodeElements::CharRepresented::Tokens
