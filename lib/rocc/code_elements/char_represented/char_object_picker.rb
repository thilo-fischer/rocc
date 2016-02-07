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

require 'rocc/session/logging'

module Rocc::CodeElements::CharRepresented

  class CharObjectPicker
    
    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    include Rocc::Helpers::String

    # XXX_R keep @picking_regexp internal, do not provide accessor
    attr_reader :picking_regexp

    def initialize(charobj_class, delegatees = nil)
      @charobj_class = charobj_class
      @delegatees = delegatees
      @picking_regexp = Regexp.new("\\A#{charobj_class.REGEXP.to_s}") if charobj_class.REGEXP
      #warn "XXX init charobj picker for #{@charobj_class}, regexp: #{@picking_regexp.inspect}, delegatees: #{@delegatees.inspect}"
    end # initialize

    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of this class or one of the classes noted in
    # the +@PICKING_DELEGATEES+ array, mark the according section in
    # that string as tokenized and create and return an instance of
    # the according class created from that section. Else, return nil.
    def pick!(tokenization_context)
      #warn "pick!: Class: #{@charobj_class}, regexp: #{@picking_regexp.inspect}, delegatees: #{@delegatees.inspect}"
      if @delegatees
        if @picking_regexp
          return nil unless peek(tokenization_context)
          tkn = delegate_pick!(tokenization_context)
          raise "`#{tokenization_context.remainder}' should contain #{@charobj_class.family_abbrev} according to `#{@picking_regexp}', but none of #{@delegatees.map {|d| d.family_abbrev}} matched." unless tkn
          tkn
        else
          delegate_pick!(tokenization_context)
        end
      else
        direct_pick!(tokenization_context)
      end
    end

    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of one of the classes noted in the
    # +@PICKING_DELEGATEES+ array, mark the according section in that
    # string as tokenized and create and return an instance of the
    # according class created from that section. Else, return nil.
    def delegate_pick!(tokenization_context)
      @delegatees.find {|d| d.pick!(tokenization_context)}
    end
    private :delegate_pick!
    
    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of this class, mark the according section in
    # that string as tokenized and create and return an instance of
    # this class created from that section. Else, return nil.
    def direct_pick!(tokenization_context)
      str = pick_string!(tokenization_context)
      if str
        whitespace_after = pick_whitespace!(tokenization_context)
        charobj = create_charobj(tokenization_context, str, whitespace_after)
        log.info{
          "%-16s \u21D0 pick! %-14s + %-6s, remainder: %42s" % [
            str_abbrev(charobj.name_dbg, 16),
            "`#{str_abbrev(str, 12)}'",
            "`#{str_abbrev_inline(whitespace_after, 4)}'",
            "`#{str_abbrev_inline(tokenization_context.remainder, 40)}'"
          ]
        }
        charobj
      end
    end # direct_pick!
    private :direct_pick!

    ##
    # Test if the to be tokenized string in tokenization_context
    # begins with a char object of this class. If so, return the
    # according section of that string which represents the char
    # object; else, return nil.
    def peek(tokenization_context)
      tokenization_context.remainder.slice(@picking_regexp)
    end

    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of this class, mark the according section in
    # that string which represents the char object as tokenized and
    # return that section. Else, return nil.  def
    def pick_string!(tokenization_context)
      # find regexp in string
      # remove part of string matching regexp
      # return part of string matching regexp
      #warn "pick_string!: Class: #{@charobj_class}, regexp: #{@picking_regexp.inspect}, delegatees: #{@delegatees.inspect}"
      tokenization_context.remainder.slice!(@picking_regexp)
    end # pick_string!
    # FIXME private :pick_string!
    
    def pick_whitespace!(tokenization_context)
      whitespace = tokenization_context.lstrip! || ''
    end
    # FIXME private :pick_whitespace!

    ##
    # Create token of this class from and within the given context.
    def create_charobj(tokenization_context, text, whitespace_after = nil)
      pred = tokenization_context.recent_token
      new_charobj = @charobj_class.new(tokenization_context.line, text, tokenization_context.charpos, whitespace_after, pred)
      tokenization_context.add_token(new_charobj)
      log.debug{"new char object: #{new_charobj.name_dbg}"}
      new_charobj
    end

  end # CharObjectPicker

end # module Rocc::CodeElements::CharRepresented

