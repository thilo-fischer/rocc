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

module Rocc::CodeElements::CharRepresented

  # forward declaration (sort of ...)
  class CeCoPpConditional < CeCoPpDirective;   end
  class CeCoPpCondIf      < CeCoPpConditional; end
  class CeCoPpCondNonautonomous < CeCoPpConditional; end
  class CeCoPpCondElif    < CeCoPpCondNonautonomous; end
  class CeCoPpCondElse    < CeCoPpCondNonautonomous; end
  class CeCoPpCondEndif   < CeCoPpCondNonautonomous; end

  
  # abstract base class
  class CeCoPpConditional < CeCoPpDirective

    @PICKING_DELEGATEES = [ CeCoPpCondIf, CeCoPpCondElif, CeCoPpCondElse, CeCoPpCondEndif ]
    @REGEXP = /^#\s*(if(n?def)?|elif|else|endif)\b/

    ##
    # +ppcond_group+ array shared among all conditional
    # preprocessor directives that are associated with each other,
    # i.e. represent the same level of preprocessor branching. E.g. an
    # +#if+ directive along with two +#elif+ directives, a +#else+
    # directive and a +#endif+ directive which all belong
    # together. Stores references to all those CeCoPpConditional
    # objects that share the array.
    attr_reader :ppcond_group

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @ppcond_group = nil
    end
    
    FAMILY_ABBREV = '#Cond'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    #def pursue(compilation_context)
    #  super_duty = super
    #  return nil if super_duty.nil?
    #  compilation_context.
    #end

    ##
    # Add self to an ppcond_group array and set up a reference
    # to that array.
    def associate(arg)
      raise if @ppcond_group # XXX(assert) Code to check the method is
      # used the right way to catch programming
      # errors as early as possible. Should be
      # substituted with according unit
      # tests. Can be removed in stable,
      # productive code to increase runtime
      # performane.
      ppcond_group = arg.is_a?(Array) ? arg : arg.ppcond_group
      #warn "XXXX #{name_dbg}.associate(#{ppcond_directive.name_dbg})"
      @ppcond_group = ppcond_group
      @ppcond_group << self
    end

    alias char_object_conditions conditions
    def conditions
      raise "method shall not be used on instances of CeCoPpConditional, it is ambiguous. Use char_object_conditions, ppcond_fromgroup_conditions or ppcond_own_condition instead." # XXX(assert)
    end
    attr_reader :ppcond_fromgroup_conditions
    attr_reader :ppcond_own_condition

    def ppcond_branch_conditions
      char_object_conditions.
        conjunction(ppcond_fromgroup_conditions).
        conjunction(ppcond_own_condition)
    end

    private
    
    def make_stack_top
      compilation_context.ppcond_stack.push(self)
    end

    def replace_stack_top
      pop_stack
      summit_stack
    end

    def pop_stack
      popped = compilation_context.ppcond_stack.pop
      raise unless popped == @ppcond_group[-2] # XXX(assert)
    end

  end # class CeCoPpConditional


  class CeCoPpCondIf < CeCoPpConditional

    @REGEXP = /^#\s*if(n?def)?\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
    end

    FAMILY_ABBREV = '#If'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue(compilation_context)
      
      super_duty = super
      return nil if super_duty.nil?
      
      # CeCoPpCondIf starts ppcond_group array
      associate([])

      case text
      when /^#\s*if(?<negation>n)?def\s+(?<identifier>\w+)\s*$/,
           /^#\s*if\s*(\s|(?<negation>!))\s*defined\s*[\s\(]\s*(?<identifier>\w+)\s*[\s\)]\s*$/
        if $~[:negation]
          @condition_text = "!defined(#{$~[:identifier]})"
        else
          @condition_text = "defined(#{$~[:identifier]})"
        end
      when /^#\s*if\b(?<condition>.*)$/
        @condition_text = $~[:condition]
        @condition_text.strip!
      else
        raise "error while parsing #{logic_line.path_dbg}"
      end
      
      @ppcond_own_condition = Rocc::Semantic::CeAtomicCondition.new(@condition_text, self)

      make_stack_top
      
      nil
    end

    def ppcond_fromgroup_conditions
      Rocc::Semantic::CeEmptyCondition.instance
    end

  end # class CeCoPpCondIf

  # abstract base class 
  class CeCoPpCondNonautonomous < CeCoPpConditional

    def pursue(compilation_context)
      
      super_duty = super
      return nil if super_duty.nil?

      # collect negated_group_conditions before associate might be a
      # little more performant XXX test whether it really is,
      # otherwise associate first as that would be more convenient
      @ppcond_fromgroup_condition = negated_group_conditions

      associate(compilation_context.ppcond_stack.top)

      :handle_own_condition
    end

    private
    
    def negated_group_conditions
      if @ppcond_group.last == self
        # negate conditions of all ppcond_group except for the
        # last one because the last element in that array is self.
        @ppcond_group[0..-2]
      else
        @ppcond_group
      end.inject(Rocc::Semantic::CeEmptyCondition.instance) do |conj, c|
        #warn "#{name_dbg}.negated_associated_conditions -> #{c.name_dbg}"
        conj.conjunction(c.own_condition.negate)
      end
    end

  end # class CeCoPpCondNonautonomous
  

  class CeCoPpCondElif < CeCoPpCondNonautonomous

    @REGEXP = /^#\s*elif\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
    end

    FAMILY_ABBREV = '#Elif'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue(compilation_context)

      super_duty = super
      return nil if super_duty.nil?
      raise unless super_duty == :handle_own_condition # XXX(assert)
      
      case text
      when /^#\s*elif\s*(\s|(?<negation>!))\s*defined\s*[\s\(]\s*(?<identifier>\w+)\s*[\s\)]\s*$/
        if $~[:negation]
          @condition_text = "!defined(#{$~[:identifier]})"
        else
          @condition_text = "defined(#{$~[:identifier]})"
        end         
      when /^#\s*elif\b(?<condition>.*)$/
        @condition_text = $~[:condition]
        @condition_text.strip!
      else
        raise "error while parsing #{logic_line.path_dbg}"
      end

      @ppcond_own_condition = Rocc::Semantic::CeAtomicCondition.new(@condition_text, self)

      replace_stack_top

      nil
    end

  end # class CeCoPpCondElif

  class CeCoPpCondElse < CeCoPpCondNonautonomous

    @REGEXP = /^#\s*else\b.*$/ # TODO_R will discard all comments following the #else directive in the same line

    FAMILY_ABBREV = '#Else'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue(compilation_context)
      super_duty = super
      return nil if super_duty.nil?
      raise unless super_duty == :handle_own_condition # XXX(assert)
      
      replace_stack_top

      nil
    end

    def ppcond_own_condition
      Rocc::Semantic::CeEmptyCondition.instance
    end

  end # class CeCoPpCondElse

  class CeCoPpCondEndif < CeCoPpCondNonautonomous
    @REGEXP = /^#\s*endif\b.*$/ # TODO_R will discard all comments following the #endif directive in the same line

    FAMILY_ABBREV = '#Endif'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue(compilation_context)
      super_duty = super
      return nil if super_duty.nil?
      raise unless super_duty == :handle_own_condition # XXX(assert)

      pop_stack
      
      nil
    end

    # XXX_R useless @ppcond_fromgroup_condition (=> mixin for CeCoPpCondElif and CeCoPpCondElse?)

    # XXX_R redundant CeCoPpCondElse#ppcond_own_condition and CeCoPpCondEndif#ppcond_own_condition (=> mixin?)
    def ppcond_own_condition
      Rocc::Semantic::CeEmptyCondition.instance
    end

  end # class CeCoPpCondEndif

end # module Rocc::CodeElements::CharRepresented
