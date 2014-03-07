# -*- coding: utf-8 -*-

dbg "#{__FILE__} requires ..."

require_relative 'Token'

require_relative 'Keywords'
require_relative 'Comment'
require_relative 'Preprocessor'

dbg "#{__FILE__} ..."

class TknWord < CoToken
  # one word-charcter that is no digit
  # followed by an arbitrary number of word-charcters or digits
  @PICKING_REGEXP = /^[A-Za-z_]\w*\b/

  def self.pick!(env)
    if self.pick_string(env) then
      tkn = TknKeyword.pick!(env)
      tkn ||= super
    end
  end # pick!
 
end # TknWord

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
  # <<=, >>=, ...
  @PICKING_REGEXP = /^((<<|>>)=|...)/
end

class Tkn2Char < CoToken
  @PICKING_REGEXP = /^([+\-*\/%=!&|<>\^]=|<<|>>|##)/
end

class Tkn1Char < CoToken
  
  @PICKING_REGEXP = /^[+\-*\/%=!&|<>\^,:;?()\[\]{}~#]/
  
#  def expand(env)
#    case @text
#    when /{(\[/
#      env.bracket_stack.push self
#    when /})\]/
#      @open = env.bracket_stack.pop
#      @open.close = self
#    else
#      nil
#    end
#  end # expand

end # Tkn1Char
