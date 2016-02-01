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

    def initialize(translation_unit, fs_element_index, base_branch = nil)
      @translation_unit = translation_unit
      @main_branch = base_branch || CompilationBranch.new(self, nil, "*", [@translation_unit])
      @active_branches = [ @main_branch ].to_set
      @fs_element_index = fs_element_index
    end

    def activate_branch(branch)
      active_branches.add(branch)
    end

    def deactivate_branch(branch)
      active_branches.delete(branch)
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
    
  end # class CompilationContext

end # module Rocc::Contexts
