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

require 'rocc/semantic/symbol_index'
require 'rocc/semantic/conditions'

require 'rocc/semantic/function'

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
      warn "enter scope: #{"  " * (@scope_stack.count - 0)}> #{scope_name_dbg(scope)}"
      raise if scope == nil
      @scope_stack << scope
    end

    def current_scope
      @scope_stack.last
    end

    def finish_current_scope
      raise unless current_scope.is_a? ArisingSpecification
      symbol = current_scope.finalize(self)
      leave_scope
      symbol
    end

    def leave_scope
      warn "leave scope: #{"  " * (@scope_stack.count - 1)}< #{scope_name_dbg(@scope_stack.last)}"
      @most_recent_scope = @scope_stack.pop
    end

    attr_reader :most_recent_scope

    def find_scope(family)
      idx = @scope_stack.rindex {|s| s.is_a?(family)}
      @scope_stack[idx] if idx
    end

    private
    def scope_name_dbg(scope)
      case scope
      when Rocc::CodeElements::CodeElement
        scope.name_dbg
      else
        scope.inspect
      end
    end

    public
    
    # for debugging
    def scope_stack_trace
      result = "scope_stack of compilation branch #{id}:\n"
      @scope_stack.reverse_each do |frame|
        result += "\t#{scope_name_dbg(frame)}\n"
      end
      result
    end

    def announce_symbol(specification, symbol_family, identifier, hashargs)

      warn "announce_symbol: #{specification.inspect}, #{symbol_family.inspect}, #{identifier.inspect}, #{hashargs.inspect}"
      warn scope_stack_trace

      linkage = nil
      
      if find_scope(Rocc::Semantic::CeFunction)
        linkage = :none
      elsif hashargs.key?(:storage_class)
        case hashargs[:storage_class]
        when :typedef
          raise "not yet supported" # FIXME
        when :static
          linkage = :intern
        when :extern
          linkage = :extern # XXX what about function local symbols declared with storage class specifier extern ?
        end
      else
        linkage = symbol_family.default_linkage # XXX necessary to query symbol_familiy or is it always :extern anyways?
      end # find_scope(Rocc::Semantic::CeFunction)

      raise "programming error" unless linkage
      hashargs[:linkage] = linkage

      symbols = find_symbols(:identifier => identifier, :symbol_family => symbol_family)

      if symbols.empty?

        # symbol detected for the first time
        symbol = symbol_family.new(specification, identifier, hashargs)

      else
        
        raise if symbols.count > 1 # XXX
        symbol = symbols.first

        # FIXME compare linkage, storage_class, type_qualifiers and type_specifiers of the annonced and the indexed symbol => must be compatible
        raise "inconsistend declarations" if false # symbol.type_qualifiers != type_qualifiers or symbol.type_specifiers != type_specifiers

      end # symbols.empty?

      symbol.add_adducer(specification)

      symbol
    end # announce_symbol

    def find_symbols(criteria)
      result = []
      c = criteria.clone
      result += @symbol_idx.find_symbols(c)
      c = criteria.clone
      result += @parent.find_symbols(c) if not root?
      result
    end

    def terminate
      if has_pending?
        fail{"Branch terminated while still having pending tokens."}
        $log.debug{"Pending tokens: #{pending_to_s}"}
        return
      end
      @children.each {|c| c.terminate }
      @parent.announce_symbols(@symbol_idx)
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
    end # def fail

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
