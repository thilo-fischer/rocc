# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisly the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/contexts/lineread_context'
require 'rocc/contexts/comment_context'
require 'rocc/contexts/compilation_context'

module Rocc::Contexts

  ##
  # All-embracing context class holding the contexts used for passing
  # information in between method invokations at different levels
  # (preprocessing, tokenization, compilation/interpretation).
  #
  # This is basically a thin wrapper around LinereadContext as
  # LinereadContext references the CommentContext and the
  # CommentContext referenecs the CompilationContext. ParsingContext
  # is the only context that knows of all these specialized contexts
  # involved in rocc parsing process and about their relations to each
  # other and handles all aspects involving these relations (except
  # for one context returning a reference to its nested context, that
  # is implemented in the context itself).
  #
  #--
  #
  # XXX resolve the unintuitive issue of the very important
  # CompilationContext being "just one part" of the rather unimportant
  # CommentContext by holding all context references in the
  # ParsingContext and having references from each specific context
  # just to the ParsingContext to query the (then formally) nested
  # context?
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
