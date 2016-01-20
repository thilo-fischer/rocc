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

require 'rocc/code_elements/code_element'

# FIXME copy-paste-replace - code from statement.rb => probably needs some adaption ...

module Rocc::Semantic

  class Expression < Rocc::CodeElements::CodeElement

    attr_reader :adducer

    # origin of a expression is the scope it appears in,
    # adducer are those tokens that make up the expression
    def initialize(origin, adducer)
      super(origin)
      @adducer = adducer
    end

    def complete?
      false
    end
    
  end # class Expression

  class AtomicExpression < Expression
    alias content adducer
    # adducer is content
    def initialize(origin, adducer)
      super(origin, adducer)
    end
    def complete?
      true
    end
  end

  class CompoundExpression < Expression
    attr_reader :expressions
    # adducer is opening parenthesis token
    def initialize(origin, adducer)
      super(origin, [adducer])
      @expressions = []
    end
    def complete?
      adducer.count == 2
    end
    # add closing parenthesis token, adducer will be array with two elements
    def close(token)
      adducer << token
    end
    def opening
      adducer.first
    end
    def closing
      adducer.last
    end
    def add_expression(expression)
      @expressions << expression
    end
  end

# TODO copy-paste-replace - code from statement.rb => useful when implementing atomic expressions? Delete afterwards.
# 
## XXX private
#  
#  module ExpressionMixin
#    attr_reader :expression
#    def expression=(expression)
#      raise if @expression
#      @expression = expression
#    end
#    def expression_complete?
#      @expression and @expression.complete?
#    end
#  end
#  
#  module SubexpressionMixin
#    attr_reader :subexpression
#    def subexpression=(subexpression)
#      raise if @subexpression
#      @subexpression = subexpression
#    end
#    def substamtement_complete?
#      @subexpression and @subexpression.complete?
#    end
#  end
#
## XXX public
#
#  class ReturnExpression < Expression
#    include ExpressionMixin
#    attr_reader :function
#    def initialize(origin, adducer, function)
#      super(origin, adducer)
#      @function = function
#    end
#    def complete?
#      expression_complete?
#    end
#  end
#  
#  class IfExpression < Expression
#    include ExpressionMixin, SubexpressionMixin
#    attr_reader :else_branch
#    def initialize(origin, adducer)
#      super(origin, adducer)
#    end
#    def complete?
#      expression_complete? and substamtement_complete?
#    end
#    def else_branch=(else_branch)
#      raise if @else_branch
#      @else_branch = else_branch
#    end
#    def has_else?
#      @else_branch
#    end
#  end
#
#  class ElseExpression < Expression
#    include SubexpressionMixin
#    attr_reader if_expression
#    def initialize(origin, adducer, if_expression)
#      super(origin, adducer)
#      @if_expression = if_expression
#    end
#    def complete?
#      substamtement_complete?
#    end
#  end
#
#  class IterationExpression < Expression
#    include ExpressionMixin, SubexpressionMixin
#    def initialize(origin, adducer)
#      super(origin, adducer)
#    end
#    def complete?
#      expression_complete? and substamtement_complete?
#    end
#  end
#
#  class ForExpression < IterationExpression; end
#  class WhileExpression < IterationExpression; end
#
#  class DoWhileExpression < IterationExpression
#    # adducer is +do+ token
#    def initialize(origin, adducer)
#      super(origin, adducer)
#    end
#    # add +while+ token, adducer will be array with two elements
#    def add_while_token(token)
#      adducer = [adducer, token]
#    end
#    def do_token
#      adducer.first
#    end
#    def while_token
#      adducer.last
#    end
#  end
#
#  class BreakOrContinueExpression < Expression
#    attr_reader :affected_scope
#    def initialize(origin, adducer, affected_scope = origin)
#      super(origin, adducer)
#      @affected_scope = affected_scope
#    end
#    def complete?
#      true # FIXME what about labels? (or was this with Java?)
#    end
#  end
#
#  class ContinueExpression < BreakOrContinueExpression; end
#  class BreakExpression < BreakOrContinueExpression; end
#
#  class SwitchExpression < Expression
#    include ExpressionMixin, SubexpressionMixin
#    def initialize(origin, adducer)
#      super(origin, adducer)
#    end
#    def complete?
#      expression_complete? and substamtement_complete?
#    end
#  end
#
#  class CaseExpression < Expression
#    include ExpressionMixin, SubexpressionMixin # FIXME case is more tricky ...
#    def initialize(origin, adducer, switch_expression)
#      super(origin, adducer)
#      @switch_expression = switch_expression
#    end
#    def complete?
#      expression_complete? and substamtement_complete?
#    end
#  end
#
#  class DefaultExpression < Expression
#    include SubexpressionMixin # FIXME along with CaseExpression
#    def initialize(origin, adducer, switch_expression)
#      super(origin, adducer)
#      @switch_expression = switch_expression
#    end
#    def complete?
#      substamtement_complete?
#    end
#  end
#
#  class GotoExpression < Expression
#    attr_reader :label
#    def initialize(origin, adducer)
#      super(origin, adducer)
#    end
#    def complete?
#      @label
#    end
#    def label=(label)
#      raise if @label
#      @label = label
#    end
#  end
#
#  KEYWORD_TO_ORDINARY_EXPRESSION_MAP = (
#    :return => nil,
#    :if => IfExpression,
#    :else => nil,
#    :for => ForExpression,
#    :while => WhileExpression,
#    :do => DoWhileExpression,
#    :continue => nil,
#    :break => nil,
#    :switch => SwitchExpression,
#    :case => CaseExpression,
#    :default => DefaultExpression,
#    :goto => GotoExpression
#  )
#

end # module Rocc::Semantic
