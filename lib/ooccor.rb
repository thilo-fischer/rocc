# -*- coding: utf-8 -*-

require_relative 'CodeObjects/File'

require_relative 'compilers/compilers'

class ProcessingEnvironment
  attr_accessor :remainders, :ppcond_stack, :block_stack, :macros, :tokenization

  def initialize()
    @remainders = {}
    @ppcond_stack = []
    @block_stack = []
    @macros = {}
    @tokenization = { within_comment: FALSE }
  end

  def initialize_copy(orig)
    @remainders = @remainders.dup
    @ppcond_stack = @ppcond_stack.dup
    @block_stack = @block_stack.dup
    @macros = @macros.dup
    @tokenization = @tokenization.dup
  end

end # class ProcessingEnvironment

__END__

###############
# BACKUP CODE #
###############

class CodeProcessor

  def intialize()
    @multiline_comment = false
    @env = PpEnvironment.new    
  end # initialize()
  
  def process(l_line)

    # create copy of `text', remove whitespace
    str = l_line.text.strip

    if @multiline_comment
      if str =~ CoComment.multiline_end_regexp
        @multiline_comment = false
      end
    end
    
    tokens = []

    if str =~ CoPpDirective.regexp
#      tokens.push(CoPpDirective.strip(str))
      tokens.push(CoPpDirective.new(l_line, Regexp.last_match))
      str = Regexp.last_match.post_match
      str.lstrip!
    end
    
    until str.empty? do
      
      case str
      when CoTkWord.regexp
        tokens.push(CoTkWord.new(l_line, Regexp.last_match))
      when CoComment.regexp
        # comment will be removed below
      when CoComment.multiline_start_regexp
        @multiline_comment = true
      when CoTkStringlitral.regexp
        tokens.push(CoTkStriglitral.new(l_line, Regexp.last_match))
      when CoTkNumber.regexp
        tokens.push(CoTkNumber.new(l_line, Regexp.last_match))
      when CoTk3Char.regexp
        tokens.push(CoTk3Char.new(l_line, Regexp.last_match))
      when CoTk2Char.regexp
        tokens.push(CoTk2Char.new(l_line, Regexp.last_match))
      when CoTk1Char.regexp
        tokens.push(CoTk1Char.new(l_line, Regexp.last_match))
      else
        raise "Syntax error: `#{str}'@#{l_line.origin}"
      end
      
      str = Regexp.last_match.post_match
      str.lstrip!
      
    end # until str.empty?
    
    tokens
    
  end # parse()

end


class CaState
  attr_accessor :defines

  def initialize
    @defines = {}
  end

end # class CaState

$ca_state = CaState.new

physic_lines = []

file.text.each_with_index { |line, index|
  line_number = index + 1
  
  physic_lines.push CoPhysicLine.new file, line_number

  if line =~ /\\(\s*)$/
    warn "Warning: There is whitespace between backslash and newline in [fixme]:#{line_number}" if $1.length > 1
    next
  end

  logic_line = CoLogicLine.new physic_lines[0] .. physic_lines[-1] #fixme
  physic_lines = []

  warn "To be Comment-striped: `#{logic_line.text}'"
  # remove comments (replace by whitespace)
  line = CoComment.solve(logic_line.text)

#  puts line

  warn "To be preprocessed: `#{line}'"
  case line
  when CoPpDirective.regexp
    CoPpDirective.process line, logic_line
    next
  end

#  char_iter = line.each_char
#  parse_state = ParseStateNormal.new
#
#  loop do
#    parse_state = parse_state.process(char_iter.next)
#  end # char_iter loop

  warn "To be tokenized: `#{line}'"
  tokens = Tokenizer.new.process line

#=begin
#  token_iter = tokens.each
#
#  singlequote = 0
#  doublequote = 0
#
#  loop do
#    t = token_iter.next
#
#    if t == '"' && singlequote % 2 == 0
#      doublequote += 1
#    elsif t == "'" && doublequote % 2 == 0
#      singlequote += 1
#    elsif singlequote % 2 == 0 && doublequote % 2 == 0
#      
#      if $ca_state.defines.key?(t)
#        if $ca_state.defines[t].arguments.length > 0
#          o = token_iter.next
#          raise unless o == "("
#          arg = ""
#          r_bracket_open = 1
#          r_bracket_close = 0
#          loop do
#            a = token_iter.next
#            case a
#            when "("
#              if singlequote % 2 == 0 && 
#                  r_bracket_open += 1
#              when ")"
#                r_bracket_close += 1            
#              when "'"
#                singlequote += 1
#              when '"'
#                doublequote += 1
#              end
#              arg += a
#            end
#          else
#          end
#        end
#
#    end
#
#  end
#=end

  puts tokens.join("/")
}
