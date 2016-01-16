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

module Rocc::Contexts

  class CompilationBranch

    attr_reader :parent_branch, :conditional, :compilation_context

    def initialize(origin, conditional)
      @conditional = conditional
      case origin
      when CeTranslationUnit
        @compilation_context = CompilationContext.new(origin)
        @parent_branch = nil
      when CompilationBranch
        @compilation_context = origin.compilation_context.branch
        @parent_branch = origin
      else
        raise "Programming error :("
      end
    end

  end # class CompilationBranch

end # module Rocc
