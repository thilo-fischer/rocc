# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
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

module Rocc::Semantic

  class Statement < Rocc::CodeElements::CodeElement

    attr_reader :adducer

    # origin of a statement is the scope it appears in,
    # adducer are those tokens that make up the statement
    def initialize(origin, adducer)
      super(origin)
      @adducer = adducer
    end

    def complete?
      false
    end
    
  end # class Statement

  class CompoundStatement < Statement
    attr_reader :statements
    # adducer is opening brace token
    def initialize(origin, adducer)
      super(origin, [adducer])
      @statements = []
    end
    def complete?
      adducer.count == 2
    end
    # add closing brace token, adducer will be array with two elements
    def close(token)
      adducer << token
    end
    def opening
      adducer.first
    end
    def closing
      adducer.last
    end
    def add_statement(statement)
      @statements << statement
    end
  end

 
# XXX private
  
  module ExpressionMixin
    attr_reader :expression
    def expression=(expression)
      raise if @expression
      @expression = expression
    end
    def expression_complete?
      @expression and @expression.complete?
    end
  end
  
  module SubstatementMixin
    # XXX? differentiate between "blocks" (like switch block, ...) with special syntax and where braces are mandatory and "regular" statements that can be compound statements, but may also be any other statement where braces are not mandatory ?
    attr_reader :substatement
    def substatement=(substatement)
      raise if @substatement
      @substatement = substatement
    end
    def substamtement_complete?
      @substatement and @substatement.complete?
    end
  end

# XXX public

  class ReturnStatement < Statement
    include ExpressionMixin
    attr_reader :function
    def initialize(origin, adducer, function)
      super(origin, adducer)
      @function = function
    end
    def complete?
      expression_complete?
    end
  end
  
  class IfStatement < Statement
    include ExpressionMixin, SubstatementMixin
    attr_reader :else_branch
    def initialize(origin, adducer)
      super(origin, adducer)
    end
    def complete?
      expression_complete? and substamtement_complete?
    end
    def else_branch=(else_branch)
      raise if @else_branch
      @else_branch = else_branch
    end
    def has_else?
      @else_branch
    end
  end

  class ElseStatement < Statement
    include SubstatementMixin
    attr_reader :if_statement
    def initialize(origin, adducer, if_statement)
      super(origin, adducer)
      @if_statement = if_statement
    end
    def complete?
      substamtement_complete?
    end
  end

  class IterationStatement < Statement
    include ExpressionMixin, SubstatementMixin
    def initialize(origin, adducer)
      super(origin, adducer)
    end
    def complete?
      expression_complete? and substamtement_complete?
    end
  end

  class ForStatement < IterationStatement; end
  class WhileStatement < IterationStatement; end

  class DoWhileStatement < IterationStatement
    # adducer is +do+ token
    def initialize(origin, adducer)
      super(origin, adducer)
    end
    # add +while+ token, adducer will be array with two elements
    def add_while_token(token)
      adducer = [adducer, token]
    end
    def do_token
      adducer.first
    end
    def while_token
      adducer.last
    end
  end

  class BreakOrContinueStatement < Statement
    attr_reader :affected_scope
    def initialize(origin, adducer, affected_scope = origin)
      super(origin, adducer)
      @affected_scope = affected_scope
    end
    def complete?
      true # FIXME what about labels? (or was this with Java?)
    end
  end

  class ContinueStatement < BreakOrContinueStatement; end
  class BreakStatement < BreakOrContinueStatement; end

  class SwitchStatement < Statement
    include ExpressionMixin, SubstatementMixin
    def initialize(origin, adducer)
      super(origin, adducer)
    end
    def complete?
      expression_complete? and substamtement_complete?
    end
  end

  class CaseStatement < Statement
    include ExpressionMixin, SubstatementMixin # FIXME case is more tricky ...
    def initialize(origin, adducer, switch_statement)
      super(origin, adducer)
      @switch_statement = switch_statement
    end
    def complete?
      expression_complete? and substamtement_complete?
    end
  end

  class DefaultStatement < Statement
    include SubstatementMixin # FIXME along with CaseStatement
    def initialize(origin, adducer, switch_statement)
      super(origin, adducer)
      @switch_statement = switch_statement
    end
    def complete?
      substamtement_complete?
    end
  end

  class GotoStatement < Statement
    attr_reader :label
    def initialize(origin, adducer)
      super(origin, adducer)
    end
    def complete?
      @label
    end
    def label=(label)
      raise if @label
      @label = label
    end
  end

  KEYWORD_TO_ORDINARY_STATEMENT_MAP = {
    :return => nil,
    :if => IfStatement,
    :else => nil,
    :for => ForStatement,
    :while => WhileStatement,
    :do => DoWhileStatement,
    :continue => nil,
    :break => nil,
    :switch => SwitchStatement,
    :case => CaseStatement,
    :default => DefaultStatement,
    :goto => GotoStatement
  }


end # module Rocc::Semantic
