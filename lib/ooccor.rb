# -*- coding: utf-8 -*-

# TODOS:
# * licence information
# * test suite
# ** more tests
# ** use cucumber
# ** add unit tests
# * refactor code
# ** introduce modules
# ** adapt file structure
# *** `require' instead of `require_relative'
# *** split Lines.rb, ...
# ** "forward declarations" needed?
# *** "implemented"-hook ?
# * code documentation
# * exceptions
# ** provide appropriate exception classes
# ** review all `raise' expressions and provide appropriate messages and exception classes
# ** top-level exception handling to prevent program crashes

def dbg(str, stack = nil)
  if $DEBUG
    warn ">> #{str} (#{self.to_s}.#{caller[0] =~ /`(.*)'/; $1})"
    if stack
      caller[0..stack].each { |s| warn "^^ #{s}" }
    end
  end
end


dbg "#{__FILE__} requires ..."

require_relative 'Environment'

require_relative 'CodeObjects/Program'

require_relative 'commands/commands'
require_relative 'compilers/compilers'

dbg "#{__FILE__} ..."

# fixme: refactor
class ProcessingEnvironment

  # fixme: @remainders -> used to track phyisical lines to be merged into one logical line => refactor to more speaking naming
  attr_accessor :expansion_stack, :remainders, :bracket_stack, :tokenization, :preprocessing

  def initialize(program)
    @expansion_stack = [ program ]
    @remainders = {}
    @bracket_stack = []
    @tokenization = { :recent_token => nil, :ongoing_comment => nil, :remainder => nil, :line_offset => 0 }
    @preprocessing = { :macros => {}, :conditional_stack => [], :line_directive => nil }
  end

  def initialize_copy(orig)
    @remainders = @remainders.dup
    @bracket_stack = @bracket_stack.dup
    @tokenization = @tokenization.dup
    @preprocessing = @preprocessing.dup
  end

  # fixme: refactor (progress_file ?!)
  def end_of_file

    @tokenization[:recent_token] = nil 
    @preprocessing[:line_directive] = nil
    @preprocessing[:macros].clear

    unless @remainders.empty? and
        @bracket_stack.empty? and
        (not @tokenization[:ongoing_comment]) and
        @preprocessing[:conditional_stack].empty? and
        TRUE
      raise "Unexpected end of source code file."
    end    

  end # end_of_file

  # fixme: refactor
  def progress_token(tkn = nil, length)
    tokenization[:recent_token] = tkn if tkn
    tokenization[:line_offset] += length
    tokenization[:line_offset] += tokenization[:remainder].slice!(/^\s*/).length
    tokenization[:recent_token]
  end

end # class ProcessingEnvironment

