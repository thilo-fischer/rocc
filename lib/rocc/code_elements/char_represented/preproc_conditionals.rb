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

class CeCoPpConditional < CeCoPpDirective

    @PICKING_DELEGATEES = [ CeCoPpCondIf, CeCoPpCondElif, CeCoPpCondElse, CeCoPpCondEndif ]
    @REGEXP = /^#\s*(if(n?def)?|elif|else|endif)\b/

    ##
    # +associated_cond_dirs+ array shared among all conditional
    # preprocessor directives that are associated with each other,
    # i.e. represent the same level of preprocessor branching. E.g. an
    # +#if+ directive along with two +#elif+ directives, a +#else+
    # directive and a +#endif+ directive which all belong
    # together. Stores references to all those CeCoPpConditional
    # objects that share the array.
    attr_reader :associated_cond_dirs

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @associated_cond_dirs = nil
    end
    
    FAMILY_ABBREV = '#Cond'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue_branch(compilation_context, branch)
      #warn "XXXX #{name_dbg}.pursue_branch(..., #{branch.name_dbg})"
      branch.announce_pp_branch(self)
    end

    ##
    # Add self to an associated_cond_dirs array and set up a reference
    # to that array.
    def associate(ppcond_directive)
      return if ppcond_directive.associated_cond_dirs.last == self # no need to associate if association was already established from another compilation_branch -- TODO smells
      #warn "XXXX #{name_dbg}.associate(#{ppcond_directive.name_dbg})"
      @associated_cond_dirs = ppcond_directive.associated_cond_dirs
      @associated_cond_dirs << self
    end

  end # class CeCoPpConditional

  # XXX_R? Make an inner module of class CeCoPpConditional?
  module PpConditionalMixin

    def negated_associated_conditions
      # negate conditions of all associated_cond_dirs except for the
      # last one because the last element in that array is self.
      raise unless @associated_cond_dirs.last == self # XXX remove
      @associated_cond_dirs[0..-2].inject(Rocc::Semantic::CeEmptyCondition.instance) do |conj, c|
        #warn "#{name_dbg}.negated_associated_conditions -> #{c.name_dbg}"
        conj.conjunction(c.condition.negate)
      end
    end
    private :negated_associated_conditions

  end # module PpConditionalMixin

  # XXX_R? Make an inner module of class CeCoPpConditional?
  module PpConditionalOwnConditionMixin
    include PpConditionalMixin
    
    attr_reader :condition_text
    
    def condition
      @condition ||= Rocc::Semantic::CeAtomicCondition.new(@condition_text, self)
    end
    
    # XXX_F if self would be the first element in @associated_cond_dirs, one could invoke inject similar as in negated_associated_conditions but without an argument to get collected_conditions
    def collected_conditions
      negated_associated_conditions.conjunction(condition)
    end

  end # module PpConditionalOwnConditionMixin

  class CeCoPpCondIf < CeCoPpConditional
    include PpConditionalOwnConditionMixin

    @REGEXP = /^#\s*if(n?def)?\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
      # CeCoPpCondIf starts associated_cond_dirs array
      @associated_cond_dirs = [ self ]
    end

    FAMILY_ABBREV = '#If'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue_branch(compilation_context, branch)
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
        raise "error while parsing #{origin.path_dbg}"
      end
      super
    end

  end # class CeCoPpCondIf

  class CeCoPpCondNonautonomous < CeCoPpConditional
    def pursue_branch(compilation_context, branch)
      associate(branch.ppcond_stack.last)
      super
    end
  end # class CeCoPpCondNonautonomous

  class CeCoPpCondElif < CeCoPpCondNonautonomous
    include PpConditionalOwnConditionMixin

    @REGEXP = /^#\s*elif\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
    end

    FAMILY_ABBREV = '#Elif'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    def pursue_branch(compilation_context, branch)
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
        raise "error while parsing #{origin.path_dbg}"
      end
      super
    end

  end # class CeCoPpCondElif

  class CeCoPpCondElse < CeCoPpCondNonautonomous
    include PpConditionalMixin

    @REGEXP = /^#\s*else\b.*$/

    FAMILY_ABBREV = '#Else'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    # XXX substitute with unit test
    def pursue_branch(compilation_context, branch)
      raise "Programming error :(" unless text =~ /^#\s*else\s*$/
      super
    end

    def collected_conditions
      negated_associated_conditions
    end
    
  end # class CeCoPpCondElse

  class CeCoPpCondEndif < CeCoPpCondNonautonomous
    @REGEXP = /^#\s*endif\b.*$/

    FAMILY_ABBREV = '#Endif'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
   # XXX substitute with unit test
    def pursue_branch(compilation_context, branch)
      raise "Programming error :(" unless text =~ /^#\s*endif\s*$/
      super
    end
    
  end # class CeCoPpCondEndif

end # module Rocc::CodeElements::CharRepresented::Tokens
