# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

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
