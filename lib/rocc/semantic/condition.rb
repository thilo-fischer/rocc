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

require 'singleton' # for CeEmptyCondition

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

require 'rocc/helpers'

module Rocc::Semantic

  class CeCondition < Rocc::CodeElements::CodeElement

    include Rocc::Helpers::String

    attr_reader :adducer

    def initialize(origin, adducer)
      @adducer = adducer
    end
    
    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = 'Cond'
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
    # Return the conjunction of +self+ and +other+, i.e. the set of
    # conditions that implies +self+ *and* +other+.
    def conjunction(other)
      log.debug{"#{name_dbg}.conjunction(#{other.name_dbg})"}
      if other.is_a?(CeEmptyCondition) or
        self == other or
        self.imply?(other)
        self
      elsif other.imply?(self)
        other
      else
        # XXX? CeConjunctiveCondition.new(self, complement(other))
        CeConjunctiveCondition.new([self, other])
      end
    end

  end

  ##
  # All code found outside any preprocessor conditional branches has
  # empty conditions.
  # XXX create only one instance of CeEmptyCondition.
  class CeEmptyCondition < CeCondition

    include Singleton

    def initialize
      super(nil, nil)
    end

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = 'ECond'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def to_s
      "<always true>"
    end

    def empty?
      return true
    end
    
    ##
    # return true if self and other are equivalent
    def equivalent?(other)
      other.is_a?(CeEmptyCondition)
    end

    ##
    # return +true+ if +other+ will always be true when +self+ is true,
    # (self -> other), false otherwise.
    def imply?(other)
      equivalent?(other)
    end

    ##
    # Returns all conditions from +other+ not implied by +self+.
    # Result will be empty if +self.imply?(other)+.
    def complement(other)
      other
    end

    ##
    # Return the conjunction of +self+ and +other+, i.e. the set of
    # conditions that implies +self+ *and* +other+.
    def conjunction(other)
      other
    end

  end # class CeEmptyCondition

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

    def empty?
      return false
    end
    
    ##
    # return true if self and other are equivalent
    def equivalent?(other)
      case other
      when CeEmptyCondition
        false
      when CeAtomicCondition
        # TODO understand and compare the texts' semantics
        @text == other.text
      when CeConjunctiveCondition
        other.equivalent?(self)
      else
        raise
      end
    end

    ##
    # return +true+ if +other+ will always be true when +self+ is true,
    # (self -> other), false otherwise.
    def imply?(other)
      case other
      when CeEmptyCondition
        true
      when CeAtomicCondition
        # TODO understand and compare the texts' semantics, e.g. `A > 42' implies `A >= 42'
        equivalent?(other)
      when CeConjunctiveCondition
        not other.conditions.find do |oc|
          not imply?(oc)
        end
      else
        raise "invalid argument: `#{other}' (#{other.class})"
      end        
    end # imply?

    ##
    # Returns all conditions from +other+ not implied by +self+.
    # Result will be empty if +self.imply?(other)+.
    def complement(other)
      case other
      when CeEmptyCondition
        other
      when CeAtomicCondition
        if imply?(other)
          CeEmptyCondition.instance
        else
          other
        end
      when CeConjunctiveCondition
        CeConjunctiveCondition.new(
          other.conditions.select do |oc|
            not imply?(oc)
          end
        )
      else
        raise
      end        
    end # complement

    def negate
      # XXX pass origin? same origin for both conditions?
      @negated ||= self.class.new("!(#{@text})", origin)
    end
      
    ##
    # Return the disjunction of +self+ and +other+, i.e. the set of
    # conditions that is common in +self+ and +other+ or *is implied
    # by* +self+ *and* +other+.
    #--
    # TODO_W
    # TODO_F
    def disjunction(other)
      case other
      when CeEmptyCondition
        other
      when CeAtomicCondition
        if self == other.negate or seft.negate == other
          CeEmptyCondition.instance
        else
          raise "not yet implemented"
          CeDisjunctiveCondition.new([self, other])
        end
      when CeConjunctiveCondition
        if other.imply?(self)
          other
        elsif other.imply?(self.negate)
          self.negate.complement(other)
        else
          raise "not yet implemented"
          CeDisjunctiveCondition.new([self, other])
        end
      else
        raise "not yet implemented"
      end
    end # disjunction

 end # class CeAtomicCondition


  class CeConjunctiveCondition < CeCondition

    attr_reader :conditions

    ##
    # +conditions+ is an array of those conditions of which this
    # object represents the conjuction of.
    # CodeElement#origin is this array of conditions.
    def initialize(conditions, adducer = conditions)
      raise "invalid argument: should create CeEmptyCondition instead" if conditions.empty?
      # FIXME raise "invalid argument: conditions contains only a single element" if conditions.count == 1
      @conditions = conditions
      super(@conditions, adducer)
    end

    # Define a constant containing the string to be given as
    # FAMILY_ABBREV to avoid repeated recreation of string object from
    # string literal.
    FAMILY_ABBREV = 'CCond'
    # Return a short string giving information on the kind of the
    # character object. Return the string constant defined by the
    # current class or -- if not defined by that class -- its
    # closest ancestor defining it.
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def to_s
      '<' + @conditions.map {|c| c.to_s}.join(' <&> ') + '>'
    end

    def empty?
      @conditions.empty?
    end
    
    ##
    # return true if self and other are equivalent
    def equivalent?(other)
      if other.is_a? CeConjunctiveCondition and @conditions == other.conditions
        true
      elsif @conditions.empty?
        other.empty?
      else
        not @conditions.find do |sc|
          not sc.equivalent?(other)
        end
      end
    end # def equivalent?

    ##
    # return +true+ if +other+ will always be true when +self+ is true,
    # (self -> other), false otherwise.
    def imply?(other)
      case other
      when CeEmptyCondition
        equivalent?(other)
      when CeAtomicCondition
        @conditions.find do |sc|
          sc.imply?(other)
        end
      else
        if @conditions.empty?
          # self represents true # XXX should be CeEmptyCondition then
          false
        elsif other.conditions.empty?
          # other represents true # XXX should be CeEmptyCondition then
          true
        elsif @conditions == other.conditions
          true
        else
          not other.conditions.find do |oc|
            not imply?(other)
          end
        end
      end # case other
    end # def imply?

    ##
    # Returns all conditions from +other+ not implied by +self+.
    # Result will be empty if +self.imply?(other)+.
    def complement(other)
      case other
      when CeEmptyCondition
        other
      when CeAtomicCondition
        if imply?(other)
          CeEmptyCondition.instance
        else
          other
        end
      else
        if self == other
          CeEmptyCondition.instance
        else
          result = []
          other.conditions.each do |oc|
            case oc
            when CeEmptyCondition
              raise "CeEmptyCondition should not be part of conjunctions."
            when CeAtomicCondition
              result << oc unless imply?(oc)
            else
              comp = complement(oc)
              # FIXME smells
              case comp
              when Array
                result += comp
              when CeAtomicCondition
                result << comp
              end
            end
          end
          if result.count > 1
            CeConjunctiveCondition.new(result)
          elsif result.count == 1
            result.first
          else
            raise
          end
        end
      end
    end

    ##
    # Return the conjunction of +self+ and +other+, i.e. the set of
    # conditions that *implies* +self+ *and* +other+.
    def conjunction(other)
      if other.is_a?(CeConjunctiveCondition)
        c_dup = @conditions.dup
        c_dup += other.conditions
        CeConjunctiveCondition.new(c_dup)
      else
        super
      end
    end
    
    ##
    # Return the disjunction of +self+ and +other+, i.e. the set of
    # conditions that is common in +self+ and +other+ or *is implied
    # by* +self+ *and* +other+.
    #--
    # TODO_W
    # TODO_F
    def disjunction(other)
      case other
      when CeEmptyCondition
        other
      when CeAtomicCondition
        other.disjunction(self) # TODO_R conjunction does it the other
      # way around: call CeConjunctiveCondition#conjunction from
      # CeAtomicCondition#conjunction. Align these approaches.
      when CeConjunctiveCondition
        raise "not yet supported" unless other.conditions.map{|c| c.negate}.to_set.subset?(@conditions.to_set)
        (@conditions.to_set - other.conditions.map{|c| c.negate}).to_a
      else
        raise "not yet supported"
      end
    end

  end # class CeConjunctiveCondition    

end # module Rocc::Semantic
