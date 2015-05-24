# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'ooccor/code_objects/code_object'

module Ooccor::CodeObjects

  # forward declarations
  class CoFile < CodeObject; end


  class CoPhysicLine < CodeObject

    attr_reader :origin_offset
    alias index origin_offset

    attr_reader :line_directive

    def initialize(origin, text, origin_offset)
      super origin
      @origin_offset = origin_offset
      @text = text
      @line_directive = nil
    end

    def announce
      # Don't want to register lines, they can be referenced from the content of CoFile.
      nil
    end

    def physical_line_number
      index + 1
    end

    def line_number
      if @line_directive
        @line_directive.line_number(self)
      else
        physical_line_number
      end
    end

    def to_s
      @origin.to_s + "->" + self.class.to_s + ":" + physical_line_number.to_s
    end

    def list(format = :short)
      if @line_directive
        @line_directive.list_line(self, format)
      else
        case format
        when :explicit
          to_s
        else
          @origin.list(format) + ":" + line_number.to_s
        end
      end
    end
    

    def pred
      @origin.content[@origin_offset - 1]
    end

    def succ
      @origin.content[@origin_offset + 1]
    end

    #   def <=>(other)
    #     return @origin <=> other.origin unless other.is_a? CoPhysicLine
    #     return nil unless @origin == other.origin
    #     @line_number <=> other.line_number
    #   end

    def expand(env)

      env.expansion_stack.push self

      if env.preprocessing[:line_directive]
        @line_directive = env.preprocessing[:line_directive]
      end

      if @text =~ /\\(\w*)$/

        warn "Whitespace after backslash -- FIXME: give more info" if $1.length > 0
        if env.remainders.include? self.class
          env.remainders[self.class] << self
        else
          env.remainders[self.class] = [ self ]
        end

      else

        text = @text
        origin = self

        # merge physical lines
        if env.remainders.include? self.class
          text = env.remainders[self.class].map {|ln| ln.text.sub(/\\$/,"")}.join + text
          origin = env.remainders[self.class][0] .. self
          env.remainders.delete self.class
        end

        logic_line = CoLogicLine.new(origin, text).expand(env)

        @line_directive = logic_line.preprocessing[:line_directive]

      end

      env.expansion_stack.pop

    end # expand

    protected

    @ORIGIN_CLASS = CoFile

  end # class CoPhysicLine


end # module Ooccor::CodeObjects
