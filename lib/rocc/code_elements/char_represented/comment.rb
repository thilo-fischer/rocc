# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/code_elements/char_represented/char_object'

require 'rocc/helpers'

module Rocc::CodeElements::CharRepresented

  class CeCoComment < CeCharObject; end

  class CeCoLineComment < CeCoComment
    # from `//' to end of line
    @REGEXP = /\/\/.*$/
    FAMILY_ABBREV = 'LnCmt'
    def self.family_abbrev
      FAMILY_ABBREV
    end
  end # class CeCoLineComment
  
  class CeCoBlockComment < CeCoComment
    # from `/*' to the next (non-greedy) `*/'
    @REGEXP = /\/\*.*?\*\//
    FAMILY_ABBREV = 'BlkCmt'
    def self.family_abbrev
      FAMILY_ABBREV
    end
  end # class CeCoBlockComment

  class CeCoMultiLineBlockCommentEnd < CeCharObject
    # to the next (non-greedy) `*/'
    @REGEXP = /.*?\*\//
    FAMILY_ABBREV = 'MlCmt*/'
    def self.family_abbrev
      FAMILY_ABBREV
    end
  end # class CeCoMultiLineBlockCommentEnd

  # XXX rename MultiLine => Multiline
  class CeCoMultiLineBlockComment < CeCoBlockComment

    include Rocc::Helpers::String
    
    # from `/*' to end of line
    @REGEXP = /\/\*.*$/

    # XXX_R? origin Range instead of Array ?
    
    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super([origin], text + whitespace_after, charpos, '', direct_predecessor)
    end

    def self.create(tokenization_context, text, whitespace_after = '')
      cmt = super
      tokenization_context.announce_multiline_comment(cmt)
      cmt
    end

    ##
    # Same as CeCharObject.pick!, but not as a class method that creates an
    # according class instance when token is found, as an instance
    # method to be invoked on a class instance to extend the instance
    # with matching code sections.
    def pick_more!(tokenization_context)
      @origin << tokenization_context.line
      str = CeCoMultiLineBlockCommentEnd.picker.pick_string!(tokenization_context)
      if str
        tokenization_context.leave_multiline_comment
        @text += str
        @whitespace_after = self.class.picker.pick_whitespace!(tokenization_context)
        log.debug{ "picked `#{name_dbg}' + `#{str_no_lbreak(@whitespace_after)}', remainder: `#{tokenization_context.remainder}'" }
      else
        @text += tokenization_context.remainder
        tokenization_context.remainder.clear
      end
    end # pick_more!

    FAMILY_ABBREV = 'MlCmt'
    def self.family_abbrev
      FAMILY_ABBREV
    end

    # XXX_R Implement path, path_dbg, path_full etc. in a way that we
    # get something like `Dir/File:FirstLineNr..LastLineNr' instead of
    # `[Dir/File:FirstLineNr, ..., Dir/File:LastLineNr]'
    
  end # class CeCoMultiLineBlockComment

  # XXX_R abstract class => forbid initialization
  class CeCoComment < CeCharObject

    ##
    # Order in which to try to delegate picking to other classes is
    # important: must test for CeCoBlockComment before
    # CeCoMultiLineBlockComment.
    @PICKING_DELEGATEES = [ CeCoLineComment, CeCoBlockComment, CeCoMultiLineBlockComment ]

    @REGEXP = /\/[\/\*]/

    ##
    # CeCoComment's implementation of CodeElement#pursue.
    def pursue(compilation_context)
      super_duty = super
      return if super_duty.nil?
      log.debug{ "#{name_dbg}.pursue" }
      nil
    end

    FAMILY_ABBREV = 'Comment'
    def self.family_abbrev
      FAMILY_ABBREV
    end

    def text_abbrev
      str_abbrev(@text)
    end
    
  end # class CeCoComment

end # module Rocc::CodeElements::CharRepresented
