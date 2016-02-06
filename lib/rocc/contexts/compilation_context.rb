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

require 'rocc/contexts/compilation_branch'

module Rocc::Contexts

  class CompilationContext

    # XXX implement active_branches as method returning an iterator that recursively iterates the branches tree (performance improvement?)
    
    attr_reader :translation_unit, :active_branches, :fs_element_index

    # See open_token_request
    attr_reader :token_requester
    
    def initialize(translation_unit, fs_element_index)
      @translation_unit = translation_unit
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
    private :sync_branch_statuses

    # join as many (active) branches as possible and sync branch statuses
    def consolidate_branches
      active_branches.each {|b| b.try_join unless b == @main_branch}
      sync_branch_statuses
    end

    def terminate
      raise "unexpected termination of #{name_dbg}" unless @main_branch.finalize
    end

    def announce_symbols(symbols)
      #warn "XXXXXXXXXXXX announce_symbols \n\t#{caller[0..6].join("\n\t")}"
      @translation_unit.announce_symbols(symbols)
    end

    def find_symbols(criteria)
      #warn "XXXX CompilationContext#find_symbols#{criteria}"
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
        Rocc::Semantic::CeEmptyCondition.instance
      else
        ppcond_stack_top.ppcond_branch_conditions
      end
    end
    
  end # class CompilationContext

end # module Rocc::Contexts
