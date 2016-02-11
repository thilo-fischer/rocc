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

require 'rocc/contexts/compilation_branch'

module Rocc::Contexts

  class CompilationContext < Rocc::CodeElements::CodeElement

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    # XXX implement active_branches as method returning an iterator that recursively iterates the branches tree (performance improvement?)
    
    attr_reader :translation_unit, :active_branches, :fs_element_index

    # See open_token_request
    attr_reader :token_requester
    
    def initialize(translation_unit, fs_element_index)
      super(translation_unit)
      @translation_unit = translation_unit # XXX_R redundant to CodeElement#origin
      @main_branch = CompilationBranch.root_branch(self)
      @active_branches = [ @main_branch ].to_set
      @all_branches = @active_branches.dup
      @branches_new = Set[]
      @branches_deactivated = Set[]
      @branches_activated = Set[]
      @branches_terminated = Set[]
      @fs_element_index = fs_element_index
      @ppcond_stack = []
      @token_requester = nil
    end

    def name_dbg
      "CcCtx[#{@translation_unit.name}]"
    end

    def add_branch(branch)
      @branches_new << branch
    end

    def deactivate_branch(branch)
      @branches_deactivated << branch
    end

    def activate_branch(branch)
      @branches_activated << branch
    end

    def terminate_branch(branch)
      @branches_terminated << branch
    end

    # adapt set of active branches according to the pending branch
    # activations and deactivations
    #
    # FIXME_R Most invokations of
    # CompilationBranch#activate/deactivate happen/fork/join/terminate
    # while *not* iterating @active_branches. The according operations
    # could be processed right away from the according functions then
    # and would not require a downstream status synchronization then.
    def sync_branch_statuses
      @active_branches -= @branches_deactivated
      @branches_deactivated = Set[]
      @active_branches |= @branches_activated
      @branches_activated = Set[]

      @active_branches -= @branches_terminated
      @all_branches    -= @branches_terminated
      @branches_terminated = Set[]

      @active_banches |= @branches_new.select {|b| b.is_active?}
      @all_branches   |= @branches_new
      @branches_new = Set[]
    end

    # join as many (active) branches as possible and sync branch statuses
    def consolidate_branches
      log.debug{"active branches:       #{active_branches.map {|b| b.name_dbg}.join(', ')}"}
      # FIXME iterate through active branches of a common parent branch comparing each branch with its direct successor. (inject should do ...)
      active_branches.each do |b|
        next if b == @main_branch
        join_candidate = b.parent.forks.last
        next if b == join_candidate
        b.try_join(join_candidate)
      end
      sync_branch_statuses
      log.info{"consolidated branches: #{active_branches.map {|b| b.name_dbg}.join(', ')}"}
    end

    def terminate
      raise "unexpected termination of #{name_dbg}" unless @main_branch.finalize
    end

    def announce_symbol(symbol)
      @translation_unit.announce_symbol(symbol)
    end

    def announce_symbols(symbols)
      @translation_unit.announce_symbols(symbols)
    end

    def find_symbols(criteria)
      @translation_unit.find_symbols(criteria)
    end

    def finalize_logic_line
      if @token_requester.is_a? Rocc::Semantic::CeMacro # XXX_R smells
        close_token_request
      end
    end
    
    ##
    # Redirect all CeCharObjects to code_object instead of invoking
    # pursue on the CeCharObjects until invokation of
    # close_token_request. Logic to achive redirection is implemented
    # in CeCharObjects#pursue.
    def open_token_request(code_object)
      @token_requester = code_object
    end

    # See open_token_request
    def close_token_request
      @token_requester = nil
    end

    # See open_token_request
    def has_token_request?
      @token_requester
    end

    #attr_reader :ppcond_stack # FIXME remove, for debugging only

    def ppcond_stack_push(arg)
      @ppcond_stack << arg
    end
    
    def ppcond_stack_pop
      @ppcond_stack.pop
    end

    def ppcond_stack_empty?
      @ppcond_stack.empty?
    end
    
    def ppcond_stack_top
      @ppcond_stack.last
    end

    def current_ppcond_induced_conditions
      if ppcond_stack_empty?
        Rocc::Semantic::CeUnconditionalCondition.instance
      else
        #warn "ppcond_stack: #{@ppcond_stack}"
        ppcond_stack_top.ppcond_branch_conditions
      end
    end
    
  end # class CompilationContext

end # module Rocc::Contexts
