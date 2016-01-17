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
    
    attr_reader :active_branches

    def initialize(translation_unit)
      @translation_unit = translation_unit
      @main_branch = CompilationBranch.new(self, nil, "*")
      @active_branches = [ @main_branch ].to_set
    end

    def activate_branch(branch)
      active_branches.add(branch)
    end

    def deactivate_branch(branch)
      active_branches.delete(branch)
    end
    
    
  end # class CompilationContext

end # module Rocc::Contexts
