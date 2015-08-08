# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  class LinereadContext

    attr_reader :translation_unit, :compilation_brances, :first_continued_line, :multiline_comment

    def initialize(translation_unit)
      @translation_unit = translation_unit
      @compilation_branches = [ CompilationBranch.new(self) ]
      @first_continued_line = nil
      @multiline_comment = nil
    end
    
    def announce_continued_line(physical_line)
      @first_continued_line ||= physical_line
    end

    def leave_continued_lines
      @first_continued_line = nil
    end

    def announce_multiline_comment(comment)
      @multiline_comment ||= comment
    end

    def leave_multiline_comment
      @multiline_comment = nil
    end

  end # class LinereadContext

end # module Rocc
