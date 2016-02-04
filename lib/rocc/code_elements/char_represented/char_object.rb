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

require 'rocc/code_elements/char_represented/tokens/comment'
require 'rocc/code_elements/char_represented/tokens/preprocessor'
require 'rocc/code_elements/char_represented/tokens/token'

module Rocc::CodeElements::CharRepresented

  # XXX_R abstract class => forbid initialization
  class CeCharObject < Rocc::CodeElements::CodeElement
    
    attr_reader :text, :charpos, :pred_char_obj, :succ_char_obj, :whitespace_after

    @PICKING_DELEGATEES = [ CeCoComment, CeCoPpDirective, Tokens::CeCoToken ]

    ##
    # Conditions that must apply for this char object to "survive"
    # preprocessing.
    #
    # Will  be set when pursuing this char object.
    attr_reader :conditions

    EMPTY_WHITESPACE = ''

    ##
    # +origin+ is the logic line this char object is located in, or
    # logic line*s* in case of multiline comments.
    #
    # +text+ is the string given by this char object.
    #
    # +charpos+ is the index of the first character of the char object in
    # (the first) logic line given as +origin+.
    # 
    # +whitespace_after+ is the whitespace found after this token that
    # splits this char object from the successive char object. May be
    # an empty string.
    #
    # +pred_char_obj+ is the char object that is found directly
    # before this one.
    def initialize(origin, text, charpos, whitespace_after = nil, pred_char_obj = nil)
      super(origin)
      @text = text
      @charpos = charpos
      @whitespace_after = whitespace_after
      @pred_char_obj = pred_char_obj
      @pred_char_obj.succ_char_obj = self if @pred_char_obj
      @conditions = nil
    end # initialize

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = 'CharObj'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    # See rdoc-ref:Rocc::CodeElements::CodeElement#name_dbg
    def name_dbg
      "#{self.class.family_abbrev}[#{Rocc::Helpers::String::abbrev(Rocc::Helpers::String::no_lbreak(@text), 24)}]"
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#name
    def name
      "`#{@text}'"
    end

    # See rdoc-ref:Rocc::CodeElements::CodeElement#path_separator
    def path_separator
      ":#{@charpos} > "
    end

    def logic_line; origin; end
    
    # See rdoc-ref:Rocc::CodeElements::CodeElement#location
    #--
    # XXX aliases not listed in rdoc ?!
    # alias location path
    def location; logic_line.path; end

    ##
    # for Tokens, adducer and origin are (usually) the same
    alias adducer origin

    def self.picking_regexp
      raise "no regexp specified for class #{name}" unless @REGEXP # XXX remove
      @PICKING_REGEXP ||= Regexp.new("^(#{@REGEXP.source})") if @REGEXP
      #warn "#{name}: #{@REGEXP.inspect} -> #{@PICKING_REGEXP.inspect}"
      #@PICKING_REGEXP
    end
    
    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of this class or one of the classes noted in
    # the +@PICKING_DELEGATEES+ array, mark the according section in
    # that string as tokenized and create and return an instance of
    # the according class created from that section. Else, return nil.
    def self.pick!(tokenization_context)
      if @PICKING_DELEGATEES
        if @REGEXP
          return nil unless peek(tokenization_context)
          tkn = delegate_pick!(tokenization_context)
          raise "`#{tokenization_context.remainder}' should contain #{family_abbrev} according to `#{picking_regexp}', but none of #{@PICKING_DELEGATEES.map {|d| d.family_abbrev}} matched." unless tkn
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
    def self.delegate_pick!(tokenization_context)
      @PICKING_DELEGATEES.find {|d| d.pick!(tokenization_context)}
    end
    private_class_method :delegate_pick!
    
    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of this class, mark the according section in
    # that string as tokenized and create and return an instance of
    # this class created from that section. Else, return nil.
    def self.direct_pick!(tokenization_context)
      str = pick_string!(tokenization_context)
      if str
        whitespace_after = pick_whitespace!(tokenization_context)
        charobj = create(tokenization_context, str, whitespace_after)
        log.debug{ "pick! `#{str}' + `#{Rocc::Helpers::String::abbrev(Rocc::Helpers::String::no_lbreak(whitespace_after))}', remainder: `#{tokenization_context.remainder}'\n `=> #{charobj.name_dbg}" }
        charobj
      end
    end # direct_pick!
    private_class_method :direct_pick!

    ##
    # Test if the to be tokenized string in tokenization_context
    # begins with a char object of this class. If so, return the
    # according section of that string which represents the char
    # object; else, return nil.
    def self.peek(tokenization_context)
      tokenization_context.remainder.slice(picking_regexp)
    end

    ##
    # If the to be tokenized string in tokenization_context begins
    # with a char object of this class, mark the according section in
    # that string which represents the char object as tokenized and
    # return that section. Else, return nil.  def
    def self.pick_string!(tokenization_context)
      # find regexp in string
      # remove part of string matching regexp
      # return part of string matching regexp
      warn "remainder: #{tokenization_context.remainder.inspect}"
      warn "#{name} -> #{picking_regexp.inspect}"
      tokenization_context.remainder.slice!(picking_regexp)
    end # pick_string!
    # FIXME private_class_method :pick_string!
    
    def self.pick_whitespace!(tokenization_context)
      whitespace = tokenization_context.lstrip! || ''
      whitespace += "\n" if tokenization_context.finished?
      whitespace
    end
    # FIXME private_class_method :pick_whitespace!

    ##
    # Create token of this class from and within the given context.
    def self.create(tokenization_context, text, whitespace_after = nil)
      pred = tokenization_context.recent_token
      new_charobj = new(tokenization_context.line, text, tokenization_context.charpos, whitespace_after, pred)
      tokenization_context.add_token(new_charobj)
      log.debug{ "new token: #{new_charobj.name_dbg}" }
      new_charobj
    end

    ##
    # CharObject's implementation of CodeElement#pursue.
    def pursue(compilation_context)
      active_branches = compilation_context.active_branches

      raise "no active branches" if active_branches.empty? # XXX remove
      
      # Set conditions for this token. Conditions of a token depend
      # only on the preprocessor conditional directives and on nothing
      # else.
      @conditions = active_branches.first.ppcond_stack.inject(Rocc::Semantic::CeEmptyCondition.instance) {|conj, c| conj.conjunction(c.collected_conditions)} # FIXME smells + bad performance

      # pursue all active branches
      active_branches.each do |b|
        if b.collect_macro_tokens?
          b.greedy_macro.add_token(self)
        elsif b.has_token_request?
          b.token_requester.process_token(compilation_context, b, self)
        else
          log.debug{"#{name_dbg}.pursue_branch #{b.id}\n(#{path_dbg})\n#{b.scope_stack_trace}"} # TODO loglevel trace ?! log with specific log tag?
          pursue_branch(compilation_context, b)
        end
      end

      # join as many branches as possible
      active_branches.each {|b| b.try_join}

      log.debug{ "active branches: #{active_branches.map {|b| b.name_dbg}.join(', ')}" }
      
      # adapt set of active branches according to the branch
      # activations and deactivations that may have happened from this
      # token
      compilation_context.sync_branch_activity
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

    def succ_char_obj=(s)
      raise "already set" if @succ_char_obj
      @succ_char_obj = s
    end

  end # CeCharObject

end # module Rocc::CodeElements::CharRepresented::Tokens
