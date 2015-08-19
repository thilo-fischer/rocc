# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'lineread_context'
reauire 'comment_context'
require 'compilation_context'

module Rocc::Contexts

  ##
  # All-embracing context class holding the contexts used for passing
  # information in between method invokations at different levels
  # (preprocessing, tokenization, compilation/interpretation).
  class ParsingContext

    attr_reader :lineread_context

    def initialize(translation_unit)
      @lineread_context = LinereadContext.new(CommentContext.new(CompilationContext.new(translation_unit)))
    end

    def terminate # FIXME! getting called at end of translation_unit?
      @lineread_context.comment_context.compilation_context.terminate
      @lineread_context.comment_context.terminate
      @lineread_context.terminate
    end

  end # class ParsingContext

end # module Rocc
