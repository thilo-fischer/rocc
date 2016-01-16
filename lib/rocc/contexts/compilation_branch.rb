# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

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
