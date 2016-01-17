# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/semantic/symbol_index'

module Rocc::Contexts

  class CompilationBranch

    attr_reader :parent, :conditional, :id, :tkn_cursor, :symbols, :pending_tokens, :scope_stack, :children

    ##
    # New branch that branches from +parent+ and is active when the
    # given +conditional+ applies. +parent+ is the branch the new
    # branch derives from for usual branches, it is the current
    # CompilationContext for the initial branch. +conditional+ refers
    # to a +CePpConditional+ object, it is nil for the initial branch.
    def initialize(parent, conditional, id)
      @parent = parent
      @conditional = conditional
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

      @children = []
      @next_child_id = 0
    end

    def branch_out(conditional)
      b = new(self, conditional, @id + ".#{@next_child_id}")
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

    def find_symbols(identifier, *varargs)
      result = []
      result += @symbol_idx.find_symbols(identifier, *varargs)
      result += @parent.find_symbols(identifier, *varargs)
      result
    end

    def terminate
      raise "TODO error handling 82398237" if pending?
      @parent.annouce_symbols(@symbols)
      deactivate
    end

    ##
    # Mark this compilation branch as dead end. Log accroding message
    # if logging level is set accrodingly. token argument is begin
    # used for informational purposes only. If a block is passed to
    # the method, that block must evaluate to a String object and the
    # String object will be included in the message being logged.
    def fail(token)
      deactivate
      # FIXME need end-user-friendly logging (with conditionals' ids?)
      $log.info do
        message = yield
        "#{token.path}: Failed in processing branch #{@id}" +
          if message
            ": " + message
          else
            "."
          end
      end
      $log.warn{"Branch conditions: " + @conditions.dbg_name}
    end

    def active?
      @active
    end

    protected

    def deactivate
      @active = false
      if root?
        raise "all compilation branches ended" # FIXME
      else
        @parent.children.remove(self) # XXX ?
        @parent.deactivate unless @parent.children.find {|c| c.active? }
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

    
  end # class CompilationBranch

end # module Rocc
