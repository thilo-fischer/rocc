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

require 'rocc/contexts/compilation_branch'

module Rocc::Contexts

  class CompilationContext < Rocc::CodeElements::CodeElement

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    # XXX implement active_branches as method returning an iterator
    # that recursively iterates the branches tree (performance
    # improvement?)
    
    attr_reader :translation_unit, :fs_element_index

    # See open_token_request
    attr_reader :token_requester
    
    def initialize(translation_unit, fs_element_index)
      super(translation_unit)
      @translation_unit = translation_unit # XXX_R redundant to CodeElement#origin
      @main_branch = CompilationBranch.root_branch(self)
      @fs_element_index = fs_element_index
      @ppcond_stack = []
      @token_requester = nil
      @active = true
    end

    def name_dbg
      "CcCtx[#{@translation_unit.name}]"
    end

    def active_branches
      @main_branch.active_branches
    end
    
    # join as many (active) branches as possible
    def consolidate_branches
      log.debug{"active branches:       #{active_branches.map {|b| b.name_dbg}.join(', ')}"}
      @main_branch.consolidate_branches
      log.info {"consolidated branches: #{active_branches.map {|b| b.name_dbg}.join(', ')}"}
    end

    def terminate
      raise "unexpected termination of #{name_dbg}" unless @main_branch.finalize
      @active = false
    end

    def active_branch_adducer?
      @active
    end

    def announce_semantic_element(selem)
      @translation_unit.announce_semantic_element(selem)
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
