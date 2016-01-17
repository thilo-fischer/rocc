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

  class LinereadContext

    attr_reader :first_continued_line, :comment_context

    def initialize(comment_context)
      @comment_context = comment_context
      @first_continued_line = nil
    end
    
    def terminate
       # FIXME find something better to do than raise that string ...
     raise "not completed" unless completed?
    end

    def completed?
      @first_continued_line == nil
    end

    def announce_continued_line(physical_line)
      @first_continued_line ||= physical_line
    end

    def leave_continued_lines
      @first_continued_line = nil
    end

  end # class LinereadContext

end # module Rocc
