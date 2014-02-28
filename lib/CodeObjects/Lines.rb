# -*- coding: utf-8 -*-

require_relative 'CodeObject'

require_relative 'Comment'
require_relative 'Preprocessor'

class CoFile < CodeObject; end

class CoPhysicLine < CodeObject
  attr_reader :origin_offset, :pp_line_number, :text

  def initialize(origin, text, origin_offset)
    super origin
    @origin_offset = origin_offset

    @pp_line_number = line_number # fixme: should take preprocessor #line directive into account

    @text = text

    # warn "PL initialized : " + to_s + " => `" + text + "'"
  end

  def line_number
    @origin_offset + 1
  end

  def to_s
    @origin.to_s + ":#{line_number}->" + self.class.to_s
  end

=begin
  def text
    @origin.lines[@origin_offset]
  end
=end

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

  def process(env)

    if @text =~ /\\(\w*)$/

      warn "Whitespace after backslash -- FIXME: give more info" if $1.length > 0
      if env.remainders.include? self.class
        env.remainders[self.class].push self
      else
        env.remainders[self.class] = [ self ]
      end

      nil

    else

      text = @text
      origin = self

      if env.remainders.include? self.class and (not env.remainders[self.class].empty?)
        text.dup.prepend env.remainders[self.class].map {|ln| ln.text.sub(/\\$/,"").gsub(/^\w*|\w*$/," ")}.join
        origin = env.remainders[self.class][0] .. self

        env.remainders[self.class] = []
      end

      CoLogicLine.new(origin, text).process(env)

    end

  end # process

private

  def validate_origin(origin)
    raise type_error origin unless origin.is_a? CoFile
    origin
  end

end # class CoPhysicLine

class CoLogicLine < CodeObject
  attr_reader :text

  def initialize(origin, text)
    if origin.is_a? CodeObjectContainer
      super origin
    elsif origin.is_a? Range
      super CodeObjectContainer.new(origin, CoPhysicLine)
    elsif origin.is_a? Array # fixme: remove this case
      super CodeObjectContainer.new(origin, CoPhysicLine)
    else
      super CodeObjectContainer.new([origin], CoPhysicLine)
    end

    @text = text

#    warn "LL initialized : " + to_s + " => `" + text + "'"
  end # initialize

  def process(env)
#    if @text =~ CoPpDirective.@REG_EXP
#      CoPpDirective.new(self).process(env)
#    else
      tokenize(env).map {|t| t.process(env)}
#    end
  end # process

  def tokens
    raise "#{to_s} has not yet been tokenized." unless @tokens
    @tokens
  end
  
  alias content tokens

private

  def validate_origin(origin)
    raise type_error origin unless origin.contained_class <= CoPhysicLine
    origin
  end

  def tokenize(env)
    @tokens = []

    # create copy of `text'
    remainder = @text.dup

    # handle ongoing multiline comment
    if env.tokenization[:within_comment]
      # fixme: used "TknMultilineComment"
      if i = remainder.index(/\*\//)
        offset += remainder.slice!(/^.*?\*\/\s*/).length # fixme: use "i"
      else
        return @tokens
      end
    end

    # remove all comments
    # fixme: rework to TknComment
    CoComment.solve!(remainder)

    # remove trailing whitespace
    remainder.rstrip!
    offset = remainder.lstrip!.length

    if str = TknPpDirective.pick(remainder)
      pp_directive = TknPpDirective.create(self, offset, str)
      @tokens.push pp_directive
      offset += str.length + remainder.lstrip!.length
    else
      pp_directive = false
    end

    until remainder.empty? do
      str = ""
      if tkn_class = CoToken.PICKING_ORDER.find {|cl| str = cl.pick(remainder)}
        @token.push tkn_class.create(self, offset, str)
        offset += str.length
=begin
      if tkn_class = TknWord.pick(remainder)
        @tokens.push tkn_class
      elsif tkn_class = TknStringLiteral.pick(remainder)
        @tokens.push tkn_class
      elsif tkn_class = TknNumber.pick(remainder)
        @tokens.push tkn_class
      elsif tkn_class = Tkn3Char.pick(remainder)
        @tokens.push tkn_class
      elsif tkn_class = Tkn2Char.pick(remainder)
        @tokens.push tkn_class
      elsif tkn_class = Tkn1Char.pick(remainder)
        @tokens.push tkn_class
=end
      else
        raise "Could not dertermine next token in `#{remainder}'"
      end
    end
    
    @tokens
  end # tokenize

end # class CoLogicLine

=begin
class OngoingComment < Token
  @PICKING_REGEXP = /^.*?(\*\/|$)/
end
=end
