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

require 'rocc/code_elements/code_element'
require 'rocc/code_elements/char_represented/logic_line'

module Rocc::CodeElements::CharRepresented

  class CePhysicLine < Rocc::CodeElements::CodeElement

    ##
    # index of this element in the origin's array of lines
    attr_reader :index, :text
 
    def initialize(origin, text, index) #, ppdir_line_list = nil)
      super origin
      @index = index
      @text = text
      #@ppdir_line_list = ppdir_line_list
    end

    def announce
      # Don't want to register lines, they can be referenced from the content of CeFile.
      nil
    end

    def line_number
      index + 1
    end

    ##
    # Line number(s) associated with this line when taking into
    # account previous #line preprocessor directives. This is not
    # trivial because line directives may become active or inactive
    # depending on preprocessor conditionals -- so one line may have
    # different line numbers in different preprocessing branches.  As
    # the #line directive is a rather uncommon feature, implementation
    # of support for this is currently postponed.
    #
    # TODO not yet supported
    def line_number_assigned
      # XXX
      raise "not yet implemented"
      if ppdir_line_list
        ppdir_line_list.compute_line_number(self)
      else
        physical_line_number
      end
    end

    def name
      line_number.to_s
    end

    ##
    # previous line, nil if first line in file
    def pred
      if @index > 0
        @origin.content[@index - 1]
      else
        nil
      end
    end

    ##
    # next line, nil if last line in file
    def succ
      @origin.content[@index + 1]
    end

    #   def <=>(other)
    #     return @origin <=> other.origin unless other.is_a? CePhysicLine
    #     return nil unless @origin == other.origin
    #     @line_number <=> other.line_number
    #   end

    ##
    # Check if the line is a continued line, i.e. a line ending with a
    # backslash.  If there is whitespace between backslash and
    # newline, we do it like the gcc does: Accept it as a continued
    # line, but print according warning message.  Returns true if line
    # is a continued line with baskslash-newline, a string containing
    # a warning message if it is a continued line with whitespace in
    # between backslash and newline, false otherwise.
    def check_continued_line
      if @text =~ /\\(\w*)$/
        if $1.length == 0
          true
        else
          path + ": warning: whitespace between backslash and newline." # XXX more verbose warning message, print column of whitespace and @text
        end
      else
        false
      end
    end

    def pursue(lineread_context)

      continued = check_continued_line()
      warn continued if continued.class.is_a? String
      
      if continued
        lineread_context.announce_continued_line(self)
      else
        
        if lineread_context.completed?
          logic_line = CeLogicLine.new(self)
        else
          logic_line = CeLogicLine.new(lineread_context.first_continued_line .. self)
          lineread_context.leave_continued_lines
        end

        logic_line.pursue(lineread_context)
        
      end

     end # pursue

    protected

#    @ORIGIN_CLASS = CeFile

    def path_separator
      ":"
    end

  end # class CePhysicLine


end # module Rocc::CodeElements::CharRepresented