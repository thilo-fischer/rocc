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
    
    def initialize(translation_unit, fs_element_index, base_branch = nil)
      @translation_unit = translation_unit
      @main_branch = base_branch || CompilationBranch.root_branch(self)
      @active_branches = [ @main_branch ].to_set
      @next_active_branches = @active_branches.dup
      @branches_for_deactivation = Set[]
      @fs_element_index = fs_element_index
      @token_requester = nil
    end

    def activate_branch(branch)
      @next_active_branches.add(branch)
    end

    def deactivate_branch(branch)
      @next_active_branches.delete(branch)
    end

    def sync_branch_activity
      # TODO_F Set of active branches will be the same for most
      # tokens, and changes will affect only few branches. Collect and
      # apply diff of branches to activate and deactivate instead of
      # altering a copy of the active_branches set.
      @active_branches = @next_active_branches.dup
    end

    def terminate
      @main_branch.terminate
    end

    def announce_symbols(symbols)
      @translation_unit.announce_symbols(symbols)
    end

    def finalize_logic_line
      active_branches.each do |b|
        if b.collect_macro_tokens?
          b.stop_collect_macro_tokens
        elsif b.has_token_request?
          raise "newline within macro invokation (or programming error)" # FIXME is this an error condition? shouldn't newline characters be allowed withn macro *invokations* (in contrast to macro *definitions*) ?!?
        end
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
    
  end # class CompilationContext

end # module Rocc::Contexts
