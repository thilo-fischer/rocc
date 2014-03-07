# -*- coding: utf-8 -*-

dbg __FILE__

require_relative 'CodeObject'

# forward declarations
class CoFile < CodeObject; end

require_relative 'Tokens/tokens'

class CoPhysicLine < CodeObject

  attr_reader :origin_offset
  alias index origin_offset

  attr_reader :line_directive

  def initialize(origin, text, origin_offset)
    super origin
    @origin_offset = origin_offset
    @text = text
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
        @origin.list(format) + ":" + line_number
      end
    end
  end
 

  def pred
    @origin.content[@origin_offset - 1]
  end

  def succ
    @origin.content[@origin_offset + 1]
  end

=begin
  def <=>(other)
    return @origin <=> other.origin unless other.is_a? CoPhysicLine
    return nil unless @origin == other.origin
    @line_number <=> other.line_number
  end
=end

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

      CoLogicLine.new(origin, text).expand(env)
    end

    env.expansion_stack.pop

  end # expand

protected

  @ORIGIN_CLASS = CoFile

end # class CoPhysicLine



class CoLogicLine < CodeObject

  def initialize(origin, text)
    super CoContainer.new(origin)
    @text = text
    @tokens = nil
  end # initialize

  def expand(env)
    env.expansion_stack.push self
    tokenize(env).map {|t| t.expand(env)}
    env.expansion_stack.pop
  end # expand

  def tokens
    raise "#{to_s} has not yet been tokenized." unless @tokens
    @tokens
  end
  
  alias content tokens

private

  def validate_origin(origin)
    raise type_error origin unless origin.is_a? CoContainer
    origin.validate_origin CoPhysicLine
  end


  def tokenize(env)

    dbg "Tokenizing line -> "

    # create copy of `text'
    env.tokenization[:remainder] = remainder = @text.dup
    env.tokenization[:line_offset] = 0
    
    @tokens = []
    tkn = nil

    if env.tokenization[:ongoing_comment]
      # handle ongoing multi line comment
      tkn = TknMultiLineBlockComment.pick!(env)
      @tokens << tkn if tkn
    end

    # remove leading and trailing whitespace
    remainder.rstrip!
    env.tokenization[:line_offset] += remainder.slice!(/^\s*/).length

    # handle comments interfering with preprocessor directives
    while tkn = TknComment.pick!(env)
      @tokens << tkn if tkn
    end
    return @tokens if remainder.empty?
    if remainder[0] == "#" then
      remainder[0] = ""
      env.tokenization[:line_offset] += remainder.slice!(/^\s*/).length
      while tkn = TknComment.pick!(env)
        @tokens << tkn if tkn
      end    
      remainder.prepend "#"
    end

    # handle preprocessor directives
    tkn = TknPpDirective.pick!(env)
    @tokens << tkn if tkn

    until remainder.empty? do
      if CoToken::PICKING_ORDER.find {|c| tkn = c.pick!(env)}
        @tokens << tkn
      else
        raise "Could not dertermine next token in `#{remainder}'"
      end
    end
    
    @tokens

  end # tokenize

end # class CoLogicLine

