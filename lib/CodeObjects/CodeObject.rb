# -*- coding: utf-8 -*-

=begin
class Position
  attr_reader :code_object, :offset

  def initialize(code_object, offset)
    @code_object = code_object
    @offset = offset
  end

  def to_s
    @code_object.to_s + ":" + @offset.to_s
  end

end

class Origin
  attr_reader :position

  def initialize(position)
    @position = position
  end
end
=end


class CodeObject
  attr_reader :origin

  @instances = []

  def initialize(origin = nil)
    @origin = validate_origin origin
    CodeObject.register self
  end

  def to_s
    if @origin
      @origin.to_s + "->" + self.class.to_s
    else
      self.class.to_s
    end
  end

  def process(env)
    content.map{ |c| c.process(env) }
  end

  def leaf?
    false
  end

  def self.register(ref)
    @instances.push(ref)
  end

  def self.get_all_of_class
    @instances
  end

  def self.get_all_of_kind
    @instances
  end

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

  def type_error(object)
    if object
      TypeError.new("`#{object}' is of wrong type `#{object.class}'")
    else
      TypeError.new("Object of certain type expected, but got nil.")
    end  
  end

private

  def validate_origin(origin)
    raise type_error origin unless origin.is_a? CodeObject
    origin
  end

=begin
 or
      ( @origin.is_a? Array and @origin.all? { |o| o.is_a? CodeObject } ) or
      @origin == nil
    }

    ok = true    
    ok &= yield if block_given?
    if o_class != nil
      ok &= @origin.is_a?(o_class) ||
        ( @origin.is_a?(Array) && @origin.all? { |o| o.is_a? o_class } )
    end
  end

  def raise_origin_assertion
    raise "Assertion failed for `#{@origin||"*nil*"}'"
  end
=end

end # class CodeObject


class CodeObjectContainer < CodeObject

  attr_reader :contained_class

  def initialize(origin, contained_class = CodeObject)
    @contained_class = contained_class
    super origin
  end

  def text
    origin.map{ |o| o.text }
  end

  def to_s
    if origin.is_a? Range
      if origin.first != origin.last
        "[" + origin.first.to_s + ".." + origin.last.to_s + "]"
      else
        origin.first.to_s
      end
    else
      "[" + origin.map{ |o| o.to_s }.join(",") + "]"
    end
  end
  
private

  def validate_origin(origin)
    if origin.respond_to? :each
      origin.each { |o| raise type_error o unless o.is_a? @contained_class }
    else
      raise TypeError "`#{object}' is no Enumerable. (Is of class `#{object.class}'.)"
    end
    origin
  end

end # class CodeObjectContainer

