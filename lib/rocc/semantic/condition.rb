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
require 'rocc/code_elements/char_represented/tokens/preprocessor.rb'

require 'rocc/helpers'

module Rocc::Semantic

  class CeCondition < Rocc::CodeElements::CodeElement

    attr_reader :adducer

    def initialize(origin, adducer)
      @adducer = adducer
    end
    
    def name_dbg
      "#{original_to_s}{#{Rocc::Helpers::String::abbrev(to_s, 64)}}"
    end

    ##
    # Return the conjunction of +self+ and +other+, i.e. the set of
    # conditions that implies +self+ *and* +other+.
    def conjunction(other)
      log.debug{"#{name_dbg}.conjunction(#{other} -> #{other.class})"}
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

    def to_s
      "<always true>"
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

    def to_s
      @text
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
    end

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
        CeConjunctiveCondition.new(other.conditions.select do |oc|
                                     not imply?(oc)
                                   end)
      else
        raise
      end        
    end

    def negate
      # XXX pass origin? same origin for both conditions?
      @negated ||= self.class.new("!(#{@text})", origin)
    end
      

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

    def to_s
      '(' + @conditions.map {|c| c.to_s}.join(' <&> ') + ')'
    end

    ##
    # return true if self and other are equivalent
    def equivalent?(other)
      if other.is_a? CeConjunctiveCondition and @conditions == other.conditions
        true
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
    # conditions that implies +self+ *and* +other+.
    def conjunction(other)
      if other.is_a?(CeConjunctiveCondition)
        c_dup = @conditions.dup
        c_dup += other.conditions
        CeConjunctiveCondition.new(c_dup)
      else
        super
      end
    end
    
  end # class CeConjunctiveCondition    

end # module Rocc::Semantic
