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

module Rocc::Contexts

  class CommentContext

    attr_reader :multiline_comment, :compilation_context

    def initialize(compilation_context)
      @compilation_context = compilation_context
      @multiline_comment = nil
    end
    
    def terminate
      # FIXME find something better to do than raise that string ...
      raise "not completed" unless completed?
    end

    def completed?
      @multiline_comment == nil
    end

    def announce_multiline_comment(comment)
      @multiline_comment ||= comment
    end

    def leave_multiline_comment
      @multiline_comment = nil
    end

  end # class CommentContext

end # module Rocc
