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

require 'rocc/semantic/symbol_index'
require 'rocc/semantic/conditions'

module Rocc::Contexts

  class CompilationBranch

    attr_reader :parent, :conditional, :id, :tkn_cursor, :symbols, :pending_tokens, :scope_stack, :children

    ##
    # New branch that branches from +parent+ and is active when the
    # given +conditional+ applies. +parent+ is the branch the new
    # branch derives from for usual branches, it is the current
    # CompilationContext for the initial branch. +conditional+ refers
    # to a +CePpConditional+ object, it is nil for the initial branch.
    def initialize(parent, conditions, id)
      @parent = parent
      @conditions = Rocc::Semantic::Conditions.new(conditions)
      @id = id

      case @parent
      when CompilationContext
        @tkn_cursor = nil
      when CompilationBranch
        @tkn_cursor = @parent.tkn_cursor
      else
        raise "programming error"
      end
      
      @active = true
      
      @symbol_idx = Rocc::Semantic::SymbolIndex.new

      @pending_tokens = []

      @scope_stack = []

      @arising = nil

      @children = []
      @next_child_id = 0
    end

    # FIXME rename branch_out -> fork
    def branch_out(condition)
      b = new(self, @conditions + condition, @id + ".#{@next_child_id}")
      @children << b
      @next_child_id += 1
    end

    def has_children?
      not children.empty?
    end
    
    def root?
      @parent.is_a? CompilationContext
    end

    def push_pending(token)
      @pending_tokens << token
    end

    def clear_pending
      @pending_tokens = []
    end

    def has_pending?
      not @pending_tokens.empty?
    end

    def pending_to_s
      @pending_tokens.inject("") {|str, tkn| str + tkn.text + tkn.whitespace_after }
    end

    def enter_scope(scope)
      @scope_stack << scope
    end

    def current_scope
      @scope_stack.last
    end

    def leave_scope
      @scope_stack.pop
    end

    def arising=(arising)
      if @arising and not arising < @arising
        raise "inconsistent arisings detected"
      end
      @arising = arising
    end

    def arising
      @arising
    end

    def finalize_arising
      arising = @arising
      @arising = nil
      arising
    end

    def find_symbols(identifier, *varargs)
      result = []
      result += @symbol_idx.find_symbols(identifier, *varargs)
      result += @parent.find_symbols(identifier, *varargs) if not root?
      result
    end

    def terminate
      if has_pending?
        fail{"Branch terminated while still having pending tokens."}
        $log.debug{"Pending tokens: #{pending_to_s}"}
        return
      end
      @children.each {|c| c.terminate }
      @parent.annouce_symbols(@symbols)
      deactivate
    end

    ##
    # Mark this compilation branch as dead end. Log according message
    # if logging level is set accrodingly. If a block is passed to
    # the method, that block must evaluate to a String object and the
    # String object will be included in the message being logged.
    def fail
      deactivate
      $log.warn do
        message = yield
        "Failed processing branch #{@id}" +
          if message
            ": #{message}"
          else
            "."
          end
      end
      $log.info "Conditions of failed branch: #{@conditions.dbg_name}"
    end

    def active?
      @active
    end

    def activate(branch = self)      
      @active = true if branch == self
      if root?
        parent.activate_branch(branch)
      else
        parent.activate(branch)
      end
    end
      
    def deactivate(branch = self)      
      @active = false if branch == self
      if root?
        parent.deactivate_branch(branch)
      else
        parent.deactivate(branch)
      end
    end
      
#    def progress_token(tkn = nil, length)
#      @recent_token = tkn if tkn
#      @line_offset += length
#      @line_offset += @remainder.slice!(/^\s*/).length
#      @recent_token
#    end
#
#    private
#
#    def setup(master)
#      @tkn_cursor = master.tkn_cursor
#      ## XXX Which gives better performance? Copy the arrays and add to those copies or adding to empty arrays and collecting the elements of all arrays when looking for an entry?
#      #@macros = master.macros.dup
#      @symbols = master.symbols.branch
#    end

    def conditions
      
    end
    
  end # class CompilationBranch

end # module Rocc
