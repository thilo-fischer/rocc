# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects::Tokens

  class TknWord < CoToken
    # one word-charcter that is no digit
    # followed by an arbitrary number of word-charcters or digits
    @PICKING_REGEXP = /^[A-Za-z_]\w*\b/

    def self.pick!(env)
      if self != TknWord
        # allow subclasses to call superclasses method implementation
        super
      else
        if pick_string(env) then
          tkn = TknKeyword.pick!(env)
          tkn ||= super
        end
      end
    end # pick!
    
    def expand(env)
      if env.preprocessing[:macros].key?(@name) then
        macros = env.preprocessing[:macros][@name]
        macros.each do |m|
          if m.origin(LogicLine).conditions.empty?
            m.tokens
            # TODO
          end
          # TODO
        end
      end
      # TODO
    end # expand

  end # TknWord

  class TknStringLiteral < CoToken
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
    @PICKING_REGEXP = /^((<<|>>)=|\.\.\.)/
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

end # module Ooccor::CodeObjects::Tokens
