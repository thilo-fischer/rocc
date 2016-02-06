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

require 'rocc/code_elements/char_represented/char_object_picker'

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented
  class CeCharObject < Rocc::CodeElements::CodeElement; end
end

require 'rocc/code_elements/char_represented/comment'
require 'rocc/code_elements/char_represented/preprocessor'
require 'rocc/code_elements/char_represented/tokens/token'

module Rocc::CodeElements::CharRepresented

  # XXX_R abstract class => forbid initialization
  class CeCharObject < Rocc::CodeElements::CodeElement
    
    attr_reader :text, :charpos, :pred_char_obj, :succ_char_obj, :whitespace_after

    # Delegate to CeCoComment and Tokens::CeCoToken. CeCoPpDirective
    # will be handled separately as these will always start at the
    # beginning of a logic line.
    # 
    # TODO_R separate CodeObjects base class from definition of
    # picking delegation
    @PICKING_DELEGATEES = [ CeCoComment, Tokens::CeCoToken ]

    # XXX_R? Make @PICKING_DELEGATEES and @REGEXP a class instance
    # variable or a constant? (class instance variable seems more
    # appropriate as this will not be inherited by subclasses)
    class << self
      #attr_reader :PICKING_DELEGATEES
      attr_reader :REGEXP
    end
    
    # TODO_R(pickers) Rework relation of CodeObjects and their
    # pickers. Is it a good idea to separate CodeObjects and their
    # pickers from each other completely (Single responsibility
    # principle?) or should those two classes be merged together
    # completely (because they depend so much on each other)? Of which
    # object should @PICKING_DELEGATEES, @REGEXP and @PICKING_REGEXP
    # be part of and where shall these get defined?!
    #
    # Should be possible to +require+ some token without enforcing to
    # require char_object.rb which requires comment, preprocessor and
    # token which in turn require other files such that in the end
    # *all* char objects' files are +required+.
    
    def self.picker
      @picker ||= CharObjectPicker.new(self, @PICKING_DELEGATEES)
    end
    # FIXME_R private_class_method :picker
    
    def self.pick!(tokenization_context)
      picker.pick!(tokenization_context)
    end

    def self.peek(tokenization_context)
      picker.peek(tokenization_context)
    end

    ##
    # Conditions that must apply for this char object to "survive"
    # preprocessing.
    #
    # Will  be set when pursuing this char object.
    attr_reader :existence_conditions

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
      @existence_conditions = nil
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

    ##
    # CharObject's implementation of CodeElement#pursue.
    def pursue(compilation_context)
      # Set existence_conditions for this char
      # object. Existence_Conditions of a char object depend only on
      # the preprocessor conditional directives and on nothing else.
      @existence_conditions = compilation_context.current_ppcond_induced_conditions
      true
    end

    protected

    def succ_char_obj=(s)
      raise "already set" if @succ_char_obj
      @succ_char_obj = s
    end

  end # CeCharObject

end # module Rocc::CodeElements::CharRepresented::Tokens
