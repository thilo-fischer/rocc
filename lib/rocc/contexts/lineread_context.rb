# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  class LinereadContext

    attr_reader :translation_unit, :compilation_brances, :first_continued_line

    def initialize(translation_unit)
      @translation_unit = translation_unit
      @compilation_branches = [ CompilationBranch.new(self) ]
      @first_continued_line = nil
      #@ongoing_comment = nil
    end
    
    def announce_continued_line(physical_line)
      @first_continued_line ||= physical_line
    end

    def clear_continued_lines
      @first_continued_line = nil
    end

  end # class LinereadContext

end # module Rocc
