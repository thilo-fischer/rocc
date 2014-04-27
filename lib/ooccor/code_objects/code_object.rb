# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects

  # Base class for all artifacts ooccor may identify when analysing source code.
  # All child classes shall get the prefix `Co' for *C*ode*O*bject to prevent name clashes with Ruby keywords or (std) lib identifiers, e.g. CoFile < CodeObject.

  class CodeObject

    def initialize(origin = nil)
      # @origin = validate_origin origin
      @origin = origin
      @origin.register(self) if @origin
    end


    def origin(depth = 1)
      case depth
      when Integer
        if depth == 0
          self
        elsif depth > 0
          @origin.origin(depth - 1)
        else
          raise
        end
      when Class
        raise unless depth < CodeObject
        if self.is_a? depth then
          self
        elsif self.is_a? CoProgram
          nil
        else
          @origin.origin(depth)
        end
      else
        raise
      end
    end # origin


    def to_s
      if @origin
        @origin.to_s + "->" + self.class.to_s
      else
        self.class.to_s
      end
    end
    
    def list(format = :short)
      if format == :short
        self.class.to_s
      else
        to_s
      end
    end

    # todo: rename/refactor to `parse' (?)
    def expand(env)
      env.expansion_stack.push self
      dbg "expansion stack: #{env.expansion_stack.inspect}"
      content.map{ |c| c.expand(env) }
      env.expansion_stack.pop
    end

    def register(obj)
      @origin.register obj
    end

    # fixme
    def <=>(other)
      if @origin == other.origin
        if self.respond_to?(:origin_offset)
          return self.origin_offset <=> other.origin_offset
        else
          return 0
        end
      else
        return @origin <=> other.origin
      end
    end

    protected

    @ORIGIN_CLASS = CodeObject
    class << self
      attr_reader :ORIGIN_CLASS
    end

    def type_error(object)
      if object
        TypeError.new("`#{object}' is of wrong type `#{object.class}'")
      else
        TypeError.new("Object of certain type expected, but got nil.")
      end  
    end

    private
    
    def validate_origin(origin)
      raise type_error(origin) unless origin.is_a?(self.class.ORIGIN_CLASS)
      origin
    end
    
  end # class CodeObject


  class CoContainer < CodeObject

    def initialize(elements)
      elements = [elements] unless elements.is_a? Enumerable
      @origin = elements
    end

    alias content origin

    def to_s
      case
      when @origin.is_a?(Range)
        "[" + @origin.first.to_s + ".." + @origin.last.to_s + "]"
      else
        "[" + @origin.map{ |o| o.to_s }.join(",") + "]"
      end
    end

    def register(obj)
      @origin.first.register obj
    end

    def append(obj)
      # todo: validate obj.class
      case @origin
      when Array
        @origin << obj
      when Range
        raise "todo"
      else
        raise "Unexpected centainer class: `#{@origin.class}'"
      end
    end

    def validate_origin(valid_class)
      #fixme -- origin.each { |o| raise type_error(o) unless o.is_a?(valid_class) }
      self # fixme
    end

  end # class CodeObjectContainer

end # module Ooccor::CodeObjects
