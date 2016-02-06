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


# TODO_R classes in this file are classes with some aspects which make
# them CeCharObjects and some aspects which go beyond the scope of
# typical CharObjects and would be more suitable for classes from the
# (current) Rocc::Semantics module.

module Rocc::CodeElements::CharRepresented

  # forward declaration (sort of ...)
  class CeCoPpConditional < CeCoPpDirective;   end
  class CeCoPpCondIf      < CeCoPpConditional; end
  class CeCoPpCondNonautonomous < CeCoPpConditional; end
  class CeCoPpCondElif    < CeCoPpCondNonautonomous; end
  class CeCoPpCondElse    < CeCoPpCondNonautonomous; end
  class CeCoPpCondEndif   < CeCoPpCondNonautonomous; end
  
  class CePpCondGroup < Rocc::CodeElements::CodeElement

    attr_reader :if_directive, :elif_directives, :else_directive, :end_directive

    attr_reader :affected_branches

    ##
    # origin is the enclosing CeCoPpConditional if any, or translation
    # unit otherwise.
    #
    # adducer is an array of all CeCoPpConditionals part of the group.
    def initialize(compilation_context)
      if compilation_context.ppcond_stack_empty?
        super(compilation_context.translation_unit)
      else
        super(compilation_context.ppcond_stack_top)
      end
      @affected_branches = compilation_context.active_branches.dup
    end

    # XXX_R smells
    def add(arg)
      case arg
      when CeCoPpCondIf
        add_if(arg)
      when CeCoPpCondElif
        add_elif(arg)
      when CeCoPpCondElse
        add_else(arg)
      when CeCoPpCondEndif
        add_end(arg)
      else
        raise "invalid argument"
      end
    end
    
    def add_if(arg)
      raise if @if_directive # XXX(assert)
      @if_directive = arg
    end
    
    def add_elif(arg)
      @elif_directives = [] unless @elif
      @elif_directives << arg
    end

    def add_else(arg)
      raise if @else_directive # XXX(assert)
      @else_directive = arg
    end

    def add_end(arg)
      raise if @end_directive # XXX(assert)
      @end_directive = arg
    end

    def directives
      result = [@if_directive]
      result += @elif_directives if @elif_directives
      result << @else_directive if @else_directive
      result << @end_directive if @end_directive
      result
    end

    alias adducer directives

    # Conjunction of negations of the conditions of those directives
    # in the group. If +until_directive+ is given, take into account
    # only those directives before +until_directive+.
    #
    # E.g. if group consists of #ifdef FOO #elif defined(BAR) #elif
    # BAZ == 42 #else #endif then negated_conditions until +#elif BAZ
    # == 42+ is +!defined(FOO) && !defined(BAR)+, negated_conditions
    # until +#else+, +#endif+ or without any limit is +!defined(FOO)
    # && !defined(BAR) && !(BAZ == 42)+.
    def negated_conditions(until_directive = nil)
      until_directive ||= @else_directive || @end_directive
      directives.inject(Rocc::Semantic::CeEmptyCondition.instance) do |conj, c|
        return conj if c == until_directive
        conj.conjunction(c.own_condition.negate)
      end
    end
    
  end # class CePpCondGroup

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
      ppcond_group = arg.is_a?(CePpCondGroup) ? arg : arg.ppcond_group
      @ppcond_group = ppcond_group
      @ppcond_group.add(self)
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
    
    def make_stack_top(compilation_context)
      compilation_context.ppcond_stack.push(self)
    end

    def replace_stack_top(compilation_context)
      pred = pop_stack(compilation_context)
      summit_stack(compilation_context)
      pred
    end

    def pop_stack(compilation_context)
      popped = compilation_context.ppcond_stack.pop
      raise unless popped == @ppcond_group[-2] # XXX(assert)
    end

    def branch_out(compilation_context)
      branching_condition = @ppcond_group.negated_conditions(self).conjunction(ppcond_own_condition)
      @ccbranches = []
      @ppcond_group.affected_branches.each do |branch|
        @ccbranches << branch.fork(branching_condition, self)
      end
    end

    def pause_branches
      @ccbranches.each {|b| b.deactivate}
    end

    def release_branches
      @ccbranches.each {|b| b.activate} if @ccbranches
      @ccbranches = nil # to allow garbage collection of otherwise unreferenced branches
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
      
      # CeCoPpCondIf starts CePpCondGroup
      group = CePpCondGroup.new(compilation_context)
      associate(group)

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

      make_stack_top(compilation_context)

      branch_out(compilation_context)
      
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

      associate(compilation_context.ppcond_stack.top)
      @ppcond_fromgroup_condition = @ppcond_group.negated_group_conditions(self)

      :handle_own_condition
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

      pred = replace_stack_top(compilation_context)
      pred.pause_branches
      branch_out(compilation_context)
      
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
      
      pred = replace_stack_top(compilation_context)
      pred.pause_branches
      branch_out(compilation_context)

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

      pred = pop_stack(compilation_context)

      unless pred.is_a?(CeCoPpCondElse)
        # no +#else+ directive in this group => need another branch to
        # handle the path where none of the previous coditions applied
        branch_out(compilation_context)
      end

      @ppcond_group.directives.each {|d| d.release_branches}

      compilation_context.consolidate_branches
      
      nil
    end

    # XXX_R useless @ppcond_fromgroup_condition (=> mixin for CeCoPpCondElif and CeCoPpCondElse?)

    # XXX_R redundant CeCoPpCondElse#ppcond_own_condition and CeCoPpCondEndif#ppcond_own_condition (=> mixin?)
    def ppcond_own_condition
      Rocc::Semantic::CeEmptyCondition.instance
    end

  end # class CeCoPpCondEndif

end # module Rocc::CodeElements::CharRepresented
