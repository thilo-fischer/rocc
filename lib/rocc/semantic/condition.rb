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

require 'singleton' # for CeUnconditionalCondition

require 'rocc/code_elements/code_element'
require 'rocc/code_elements/char_represented/char_object' # TODO_R(pickers) `require 'rocc/code_elements/char_represented/preprocessor'' would be sufficient if only preprocessor.rb would not depend on char_object.rb and vice versa (because CeCoPpDirective is subclass of CodeObject and CodeObject references CeCoPpDirective)

# TODO_W  implement CeDisjunctiveCondition
# 
# XXX_W Analysis of strings in CeAtomicCondition (detect
# e.g. equivalence of `a != b' and `!(a==b)')
# 
# TODO_R rework API, e.g. find a way to ensure ConjucntiveConditions
# always have more than 2 entries and Atomic or Empty conditions will
# be used otherwise
# 
# TODO_R  implement based on sets insead of arrays
# 
# TODO_R  track adducers
# 
# FIXME_F much room for performance improvements
#
# TODO_R? (TODO_W??) convert all coditions to conjunctive or
# disjunctive normal form?
## Condidions shall alway be in disjunctive normal form, i.e. either
## an empty or atomic condition, a conjuction of atomic conditions or
## a disjunction of conjunctions of atomic conditions.

require 'rocc/helpers'

module Rocc::Semantic

  ##
  # Abstraction of those conditions proclaimed by conditional
  # preprocessor directives. These conditions will be instantiated
  # from conditional preprocessor directives and will be assigned to
  # compilation branches that correspond to the compilation process
  # when certain preprocessor directives' conditionals apply and will
  # be assigned to the code elements that come to life when pursuing
  # the compilation context and compilation branches.
  #
  # Given a branch +f+ that forks off from a branch +a+, and +A+ are
  # the conditions that must apply for the compilation process to run
  # along the same path as branch +a+, and +F+ are those conditions
  # that must apply for the compilation process to run along the same
  # path as branch +f+. Then there is a certain condition +Fb+ that
  # caused +f+ to branch off from +a+ called +f+'s
  # *branching_condition* and +F = A + Fb+. +F+ implies +A+ (+A+ is
  # necessity for +F+, +F+ is sufficiency for +A+).
  #
  # The symbols initialized from +f+ have +F+ as necessity and
  # sufficiency, and have +A+ as necessity. The symbols initialized
  # from +a+ have +A+ as necessity and sufficiency, and have +F+ as
  # sufficiency.
  
  class CeCondition < Rocc::CodeElements::CodeElement

    include Rocc::Helpers::String

    attr_reader :adducer

    def initialize(origin, adducer)
      @adducer = adducer
    end
    
    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = 'CondBase'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def name_dbg
      "#{self.class.family_abbrev}[#{str_abbrev(to_s, 32)}]"
    end

    ##
    # Return +true+ if +self+ and +other+ are eqivalent (+self+ ↔
    # +other+), i.e. +self+ will be true if and only if +self+ is true;
    # return false if not.
    #
    # Base class CeCondition may return nil if decision could not be
    # taken by the CeCondition#equivalent?'s implementation and
    # derived classes have to do further checks in their overriding
    # implementations to provide a valid result.
    def equivalent?(other)
      if equal?(other)
        true
      elsif other.is_a? CeUnconditionalCondition
        # nothing but a CeUnconditionalCondition is equivalent to a
        # CeUnconditionalCondition, and we know self is not a
        # CeUnconditionalCondition because self.equal?(other) did not
        # apply and CeUnconditionalCondition includes Singleton
        false
      else
        nil
      end
    end

    ##
    # Return +true+ if +self+ implies +other+ (+self+ → +other+),
    # i.e. +other+ will always be true if +self+ is true; return false
    # if not.
    #
    # Base class CeCondition may return nil if decision could not be
    # taken by the CeCondition#imply?'s implementation and derived
    # classes have to do further checks in their overriding
    # implementations to provide a valid result.
    def imply?(other)
      if equal?(other)
        true
      elsif other.is_a? CeUnconditionalCondition
        # nothing but a CeUnconditionalCondition can imply a
        # CeUnconditionalCondition, and we know self is not a
        # CeUnconditionalCondition because self.equal?(other) did not
        # apply and CeUnconditionalCondition includes Singleton
        false
      else
        nil
      end
    end

    ##
    # Return the negation of +self+ (¬+self+), i.e. a CeCondition that
    # applies if and only if +self+ does not apply.
    def negation
      @negation ||= CeNegationCondition.new(self)
    end

    ##
    # Return the conjunction of +self+ and +other+ (+self+ ∧ +other+),
    # i.e. a CeCondition that applies if and only if +self+ and
    # +other+ apply.
    def conjunction(other)
      log.debug{"#{name_dbg}.conjunction(#{other.name_dbg})"}
      case
      when other.is_a?(CeUnconditionalCondition),
           self.imply?(other)
        self
      when other.imply?(self)
        other
      when (
        (other.is_a?(CeNegationCondition) and
         self.imply?(other.negation)) or
        other.imply?(self.negation)
      )
        # `self.imply?(other.negation)' is logically equivalent to
        # `other.imply?(self.negation)'. If other is a
        # CeNegationCondition, preferably test
        # `self.imply?(other.negation)' because it won't require a
        # (possibly not yet existing) negation of self. Otherwise,
        # preferably test `other.imply?(other.negation)' (because self
        # might be a CeNegationCondition itself (as long as
        # CeNegationCondition does not override disjunction method)
        # and because it is preferable to affect self rathen than
        # other and thus run the negation method on self).
        warn "#{self}, #{other}"
        raise "contradiction, not yet implemented"
      else
        CeConjunctiveCondition.new([self, other])
      end
    end

    ##
    # Return the disjunction of +self+ and +other+ (+self+ ∨ +other+),
    # i.e. a CeCondition that applies if either +self+ applies, or
    # +other+ applies, or both apply.
    def disjunction(other)
      log.debug{"#{name_dbg}.disjunction(#{other.name_dbg})"}
      case
      when other.is_a?(CeUnconditionalCondition)
        CeUnconditionalCondition.instance
      when other.imply?(self)
        self
      when self.imply?(other)
        other
      when (
        (other.is_a?(CeNegationCondition) and
         self.imply?(other.negation)) or
        other.imply?(self.negation)
      )
        # `self.imply?(other.negation)' is logically equivalent to
        # `other.imply?(self.negation)', see comment in conjunction
        # method.
        CeUnconditionalCondition.instance
      else
        CeDisjunctiveCondition.new([self, other])
      end
    end

    def tautology?
      is_a?(CeUnconditionalCondition)
    end
    
  end

  ##
  # A CeCondition that always applies.
  # 
  # All code found outside any preprocessor conditional branches has
  # no conditions, so its necessity and sufficiency is
  # a CeUnconditionalCondition.
  class CeUnconditionalCondition < CeCondition

    include Singleton

    def initialize
      super(nil, nil)
    end

    def name_dbg
      "\u22A4Cond"
    end

    def to_s
      "\u22A4"
    end

    ##
    # +ansi_c+ If true, do *not* assume stdbool.h or C++, use +'1'+
    # and +'0'+ instead of +'true'+ and +'false'+.
    def to_code(ansi_c = false)
      ansi_c ? '1' : 'true'
    end

    ###
    ## Returns all conditions from +other+ not implied by +self+.
    ## Result will be empty if +self.imply?(other)+.
    #def complement(other)
    #  other
    #end

    # See rdoc-ref:Rocc::Semantic::CeCondition#equivalent?
    def equivalent?(other)
      other.is_a?(CeUnconditionalCondition)
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#imply?
    def imply?(other)
      other.is_a?(CeUnconditionalCondition)
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#conjunction
    def conjunction(other)
      other
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#disjunction
    def disjunction(other)
      self
    end

  end # class CeUnconditionalCondition

  ##
  # Represents the conditions usually implied by a single specific
  # preprocessor conditional directive.
  class CeAtomicCondition < CeCondition

    attr_reader :text

    def initialize(text, ppcond_dir = nil)
      super(ppcond_dir, ppcond_dir)
      @text = text
    end

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = 'ACond'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def to_s
      @text
    end

    alias to_code to_s

    # See rdoc-ref:Rocc::Semantic::CeCondition#equivalent?
    def equivalent?(other)
      sres = super
      return sres unless sres.nil?
      case other
      when CeAtomicCondition
        # TODO understand and compare the texts' semantics, e.g. `A > 42' is equivalent to `42 < A'
        @text == other.text
      when CeNegationCondition, CeSetOfConditions
        other.equivalent?(self)
      else
        raise "invalid argument"
      end
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#imply?
    def imply?(other)
      sres = super
      return sres unless sres.nil?
      case other
      when CeAtomicCondition
        # TODO understand and compare the texts' semantics, e.g. `A > 42' implies `A >= 42'
        @text == other.text
      when CeNegationCondition
        # TODO_W
        if imply?(other.negation)
          false
        elsif other.negation.is_a?(CeAtomicCondition)
          not imply?(other.negation) # XXX correct?
        else
          warn "#{self}, #{other}"
          raise "not yet implemented"
        end
      when CeConjunctiveCondition
        not other.conditions.find do |c|
          not imply?(c)
        end
      when CeDisjunctiveCondition
        other.conditions.find do |c|
          imply?(c)
        end
      else
        raise "invalid argument"
      end
    end

    ###
    ## Returns all conditions from +other+ not implied by +self+.
    ## Result will be empty if +self.imply?(other)+.
    #def complement(other)
    #  case other
    #  when CeUnconditionalCondition
    #    other
    #  when CeAtomicCondition
    #    if imply?(other)
    #      CeUnconditionalCondition.instance
    #    else
    #      other
    #    end
    #  when CeConjunctiveCondition
    #    not_implying = other.conditions.select do |oc|
    #      not imply?(oc)
    #    end
    #    case not_implying.count
    #    when 0
    #      CeUnconditionalCondition.instance
    #    when 1
    #      not_implying.first
    #    else
    #      CeConjunctiveCondition.new(not_implying)
    #    end
    #  else
    #    raise
    #  end        
    #end # complement

  end # class CeAtomicCondition

  
  ##
  # A CeCondition based on another CeCondition that applies if and
  # only if the condition it is based upon does not apply.
  class CeNegationCondition < CeCondition

    def initialize(condition, adducer = condition)
      raise "not supported" if condition.is_a?(CeUnconditionalCondition)
      super
      @negation = condition
    end

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = "\u00ACCond"
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def to_s
      "\u00AC#{@negation}"
    end

    def to_code
      "!(#{@negation})"
    end

  end # class CeUnconditionalCondition


  class CeSetOfConditions < CeCondition

    attr_reader :conditions

    def initialize(conditions, adducer = conditions)
      raise "invalid argument: should create CeUnconditionalCondition instead" if conditions.empty? # XXX(assert)
      raise "invalid argument: conditions contains only a single element" if conditions.count == 1 # XXX(assert)
      super(conditions, adducer)
      @conditions = flatten_conditions(conditions.to_set)
    end

    def flatten_conditions(input_set)
      result_set = Set.new
      input_set.each do |c|
        if c.is_a?(self.class)
          result_set.union(c.conditions)
        else
          result_set << c
        end
      end
      result_set
    end
    protected :flatten_conditions

    def merge(other)
      raise "invalid argument" unless other.class == self.class # XXX(assert)
      set_dup = @conditions.dup
      other.conditions.each do |other_c|
        set_dup << other_c unless imply?(other_c)
      end
      if set_dup.length == @conditions.length
        self
      else
        self.class.new(set_dup)
      end
    end
    protected :merge

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = "CondSet"
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end

    def join_str_to_s
      ' ~ '
    end
    private :join_str_to_s

    def join_str_to_code
      ' ~ '
    end
    private :join_str_to_code
   
    def to_s
      @conditions.map do |c|
        case c
        when CeSetOfConditions
          '(' + c.to_s + ')'
        else
          c.to_s
        end
      end.join(join_str_to_s)
    end

    def to_code
      @conditions.map {|c| '(' + c.to_s + ')'}.join(join_str_to_code)
    end

    # XXX sensible?
    def equivalent?(other)
      sres = super
      return sres unless sres.nil?
      
      if other.is_a?(self.class)
        if @conditions.equal?(other.conditions) or
           (self.imply?(other) and other.imply?(self))
          true
        else
          false
        end
      else
        nil
      end
    end
    
   # XXX sensible?
    def imply?(other)
      sres = super
      return sres unless sres.nil?
      
      if other.is_a?(self.class) and
        equivalent?(other)
          true
        else
          nil
      end
    end
    
  end
  
  class CeConjunctiveCondition < CeSetOfConditions

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = "\u2227Cond"
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def join_str_to_s
      " \u2227 "
    end
    private :join_str_to_s

    def join_str_to_code
      ' && '
    end
    private :join_str_to_code

    ##
    # Return the complement of the condition or set of conditions of
    # +other+ in the set of conditions in +self+ (based on condition
    # equivalence as defined by CeCondition#equivalent? methods),
    # i.e. all conditions from +self+ not implied by +other+.
    #
    # E.g.
    #
    # * Given two unrelated conditions A and B, then
    #    A.complement(CeConjunctiveCondition.new(A, B)) == B
    # * Given conditions A and B with <tt>A.implies?(B)</tt>, then
    #    A.complement(CeConjunctiveCondition.new(A, B)) == CeUnconditionalCondition
    #   (If A implies B, there is no condition in the conjunction not
    #   implied by A.)
    def complement(other)
      #case other
      #when CeUnconditionalCondition
      #  raise "not yet implemented"
      #when CeAtomicCondition
        cond_set = @conditions.select do |c|
          not other.imply?(c)
        end
        case cond_set.length
        when 0
          CeUnconditionalCondition.instance
        when 1
          cond_set.first
        when @conditions.length
          self
        else
          # XXX_F skip flatten_conditions in initialize method
          CeConjunctiveCondition.new(cond_set)
        end
      #when CeConjunctiveCondition
      #  # TODO_W check condition's equivalence in both sets
      #  cond_set = @conditions - other.conditions
      #  cond_set.
      #  # XXX_F skip flatten_conditions in initialize method
      #  CeConjunctiveCondition.new(cond_set)
      #else
      #  raise "invalid argument or not yet implemented"
      #end
    end

    ###
    ## Returns all conditions from +other+ not implied by +self+.
    ## Result will be empty if +self.imply?(other)+.
    #def complement(other)
    #  case other
    #  when CeUnconditionalCondition
    #    other
    #  when CeAtomicCondition
    #    if imply?(other)
    #      CeUnconditionalCondition.instance
    #    else
    #      other
    #    end
    #  else
    #    if self == other
    #      CeUnconditionalCondition.instance
    #    else
    #      result = []
    #      other.conditions.each do |oc|
    #        case oc
    #        when CeUnconditionalCondition
    #          raise "CeUnconditionalCondition should not be part of conjunctions."
    #        when CeAtomicCondition
    #          result << oc unless imply?(oc)
    #        else
    #          comp = complement(oc)
    #          # FIXME smells
    #          case comp
    #          when Array
    #            result += comp
    #          when CeAtomicCondition
    #            result << comp
    #          end
    #        end
    #      end
    #      if result.count > 1
    #        CeConjunctiveCondition.new(result)
    #      elsif result.count == 1
    #        result.first
    #      else
    #        raise
    #      end
    #    end
    #  end
    #end

    # See rdoc-ref:Rocc::Semantic::CeCondition#equivalent?
    def equivalent?(other)
      sres = super
      return sres unless sres.nil?
      
      raise "invalid argument or not yet implemented"
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#imply?
    def imply?(other)
      sres = super
      return sres unless sres.nil?
      
      case other
      when CeAtomicCondition, CeNegationCondition
        conditions.find do |own_c|
          own_c.imply?(other)
        end
      when CeConjunctiveCondition
        # return false if there is at least one condition in other not
        # implied by self
        not other.conditions.find do |other_c|
          not imply?(other_c)
        end
      when CeDisjunctiveCondition
        # return true if there is at least one condition in other
        # implied by self
        other.conditions.find do |other_c|
          imply?(other_c)
        end
     else
        raise "invalid argument or not yet implemented"
      end
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#conjunction
    def conjunction(other)
      if other.is_a?(CeConjunctiveCondition)
        merge(other)
      else
        super
      end
    end
    
    ## See rdoc-ref:Rocc::Semantic::CeCondition#disjunction
    #def disjunction(other)
    #  raise "not yet implemented"
    #end

    ###
    ## Return the disjunction of +self+ and +other+, i.e. the set of
    ## conditions that is common in +self+ and +other+ or *is implied
    ## by* +self+ *and* +other+.
    ##--
    ## TODO_W
    ## TODO_F
    #def disjunction(other)
    #  case other
    #  when CeUnconditionalCondition
    #    other
    #  when CeAtomicCondition
    #    other.disjunction(self) # TODO_R conjunction does it the other
    #  # way around: call CeConjunctiveCondition#conjunction from
    #  # CeAtomicCondition#conjunction. Align these approaches.
    #  when CeConjunctiveCondition
    #    warn "self : #{self}"
    #    warn "other: #{other}, #{other.conditions.count}"
    #    return disjunction(other.conditions.first) if other.conditions.count == 1 # XXX_R quick and dirty
    #    raise "not yet supported" unless other.conditions.map{|c| c.negate}.to_set.subset?(@conditions.to_set)
    #    (@conditions.to_set - other.conditions.map{|c| c.negate}).to_a
    #  else
    #    raise "not yet supported"
    #  end
    #end

  end # class CeConjunctiveCondition


  class CeDisjunctiveCondition < CeSetOfConditions

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = "\u2228Cond"
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def join_str_to_s
      " \u2228 "
    end
    private :join_str_to_s

    def join_str_to_code
      ' || '
    end
    private :join_str_to_code

    # See rdoc-ref:Rocc::Semantic::CeCondition#equivalent?
    def equivalent?(other)
      sres = super
      return sres unless sres.nil?
      
      raise "invalid argument or not yet implemented"
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#imply?
    def imply?(other)
      sres = super
      return sres unless sres.nil?

      case other
      when CeAtomicCondition, CeNegatedCondition, CeConjunctiveCondition, CeDisjunctiveCondition
        # return false if there is at least one condition in self not
        # implying other
        not conditions.find do |own_c|
          not own_c.imply?(other)
        end
      #when CeConjunctiveCondition
      #  # return false if there is at least one condition in other not
      #  # implied by self
      #  not other.conditions.find do |other_c|
      #    not imply?(other_c)
      #  end
      #when CeDisjunctiveCondition
      #  # return true if there is at least one condition in other
      #  # implied by self
      #  other.conditions.find do |other_c|
      #    imply?(other_c)
      #  end
      else
        raise "invalid argument or not yet implemented"
      end
    end
    
    # See rdoc-ref:Rocc::Semantic::CeCondition#disjunction
    def disjunction(other)
       if other.is_a?(CeDisjunctiveCondition)
        merge(other)
      else
        super
      end     
    end

    ###
    ## return true if self and other are equivalent
    #def equivalent?(other)
    #  case other
    #  when CeDisjunctiveCondition
    #    if @conditions == other.conditions
    #      true
    #    else
    #      not @conditions.find do |sc|
    #        not sc.equivalent?(other)
    #      end
    #    end
    #  when CeConjunctiveCondition
    #    false
    #  else
    #    raise "not yet implemented"
    #  end
    #end # def equivalent?
    #
    ###
    ## return +true+ if +other+ will always be true when +self+ is true,
    ## (self -> other), false otherwise.
    #def imply?(other)
    #  case other
    #  when CeUnconditionalCondition
    #    true
    #  when CeAtomicCondition, CeConjunctiveCondition
    #    # Only true if all contained conditions imply other,
    #    # i.e. there is no condition not implying other.
    #    not @conditions.find do |sc|
    #      not sc.imply?(other)
    #    end
    #  when CeDisjunctiveCondition
    #    if @conditions == other.conditions
    #      true
    #    else
    #      # Only true if all contained conditions imply other,
    #      # i.e. there is no condition not implying other.
    #      not @conditions.find do |sc|
    #        not sc.imply?(other)
    #      end
    #    end        
    #  else
    #    raise "not yet implemented"
    #  end
    #end # def imply?
    #
    ###
    ## Returns all conditions from +other+ not implied by +self+.
    ## Result will be empty if +self.imply?(other)+.
    #def complement(other)
    #  return CeUnconditionalCondition.instance if imply?(other)
    #  case other
    #  when CeAtomicCondition, CeConjunctiveCondition
    #    other
    #  when CeDisjunctiveCondition
    #    raise "not yet implemented"
    #  else
    #    raise "not yet implemented"
    #  end
    #end
    #
    ###
    ## Return the conjunction of +self+ and +other+, i.e. the set of
    ## conditions that *implies* +self+ *and* +other+.
    ##
    ## Will convert the result to disjunctive normal form.
    #def conjunction(other)
    #  if other.is_a?(CeConjunctiveCondition)
    #    c_dup = @conditions.dup
    #    c_dup += other.conditions
    #    CeConjunctiveCondition.new(c_dup)
    #  else
    #    super
    #  end
    #end
    #
    ###
    ## Return the disjunction of +self+ and +other+, i.e. the set of
    ## conditions that is common in +self+ and +other+ or *is implied
    ## by* +self+ *and* +other+.
    ##--
    ## TODO_W
    ## TODO_F
    #def disjunction(other)
    #  case other
    #  when CeUnconditionalCondition
    #    other
    #  when CeAtomicCondition
    #    other.disjunction(self) # TODO_R conjunction does it the other
    #  # way around: call CeConjunctiveCondition#conjunction from
    #  # CeAtomicCondition#conjunction. Align these approaches.
    #  when CeConjunctiveCondition
    #    warn "self : #{self}"
    #    warn "other: #{other}, #{other.conditions.count}"
    #    return disjunction(other.conditions.first) if other.conditions.count == 1 # XXX_R quick and dirty
    #    raise "not yet supported" unless other.conditions.map{|c| c.negate}.to_set.subset?(@conditions.to_set)
    #    (@conditions.to_set - other.conditions.map{|c| c.negate}).to_a
    #  else
    #    raise "not yet supported"
    #  end
    #end

  end # class CeDisjunctiveCondition

end # module Rocc::Semantic
