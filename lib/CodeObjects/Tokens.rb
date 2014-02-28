# -*- coding: utf-8 -*-

require_relative 'Keywords.rb'

class CodeObject; end

# forward declarations
class CoToken < CodeObject; end
class TknWord < CoToken; end
class TknStringLiteral < CoToken; end
class TknNumber < CoToken; end
class Tkn3Char < CoToken; end
class Tkn2Char < CoToken; end
class Tkn1Char < CoToken; end

class CoToken < CodeObject
  attr_reader :text, :origin_offset

  PICKING_ORDER = [ TknWord, TknStringLiteral, TknNumber, Tkn3Char, Tkn2Char, Tkn1Char ]

  def initialize(origin, origin_offset, text)
    super origin
    @origin_offset = origin_offset
    @text = text
  end

  def self.pick(str)
    # find regexp in string
    # remove part of string matching regexp
    # return part of string matching regexp 
    str.slice!(@PICKING_REGEXP)
  end

  def self.test(str)
    str =~ @PICKING_REGEXP
  end

  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end

  def process(env)
    raise "Cannot process `#{self}' of class `#{self.class}'. Only child classes of `#{self.class}' should be instanciated."
  end

private

  def validate_origin(origin)
    raise type_error origin unless origin.is_a? CoLogicLine
    origin
  end

end # CoToken

class TknWord < CoToken
  # one word-charcter that is no digit
  # followed by an arbitrary number of digits
  @PICKING_REGEXP = /^[A-Za-z_]\w*\b/

  def self.create(origin, origin_offset, str)
    if TknKeyword.test(str)
      TknKeyword.create(origin, origin_offset, str)
    else
      TknIdentifier.create(origin, origin_offset, str)      
    end
  end
end # TknWord

class TknIdentifier < TknWord
#  @PICKING_REGEXP = super.@PICKING_REGEXP
end # TknKeyword

class TknStringLitral < CoToken
  # a double quote
  # optionally followed by
  # an arbitrary number of arbitrary characters (non-greedy)
  # where the last character is no backslash
  # followed by a double quote
  @PICKING_REGEXP = /^"(.*?[^\\])?"/
end

class TknNumber < CoToken
  @PICKING_REGEXP = /^(0[xX])?(\d|\.\d)\d*\a*\b/
end

class Tkn3Char < CoToken
  @PICKING_REGEXP = /^((<<|>>)=|...)/
end

class Tkn2Char < CoToken
  @PICKING_REGEXP = /^([+\-*\/%=!&|<>\^]=|<<|>>|##)/
end

class Tkn1Char < CoToken
  @PICKING_REGEXP = /^[+\-*\/%=!&|<>\^,:;?()\[\]{}~#]/
end
