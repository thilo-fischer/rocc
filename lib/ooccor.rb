# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

# TODOS:
# * test suite
# ** more tests
# *** http://deneke.biz/2014/02/great-presentation-dark-corners-c/, https://docs.google.com/presentation/d/1h49gY3TSiayLMXYmRMaAEMl05FaJ-Z6jDOWOz3EsqqQ/edit?pli=1#slide=id.gaf50702c_0123
# ** use cucumber
# ** add unit tests
# * refactor code
# ** "forward declarations" needed?
# *** "implemented"-hook ?
# ** make some protected methods private ?
# * code documentation
# * exceptions
# ** provide appropriate exception classes
# ** review all `raise' expressions and provide appropriate messages and exception classes
# ** top-level exception handling to prevent program crashes
# * review module hierarchy and file structure


def dbg(str, stack = nil)
  if $DEBUG
    warn ">> #{str} (#{self.class.to_s}.#{caller[0] =~ /`(.*)'/; $1})"
    if stack
      caller[0..stack].each { |s| warn "^^ #{s}" }
    end
  end
end


module Ooccor

  require 'ooccor/version'

  require 'ooccor/environment'
  require 'ooccor/code_objects/program'
  require 'ooccor/commands/commands'
  require 'ooccor/compilers/compilers'

  # fixme: refactor
  class ProcessingEnvironment

    # fixme: @remainders -> used to track phyisical lines to be merged into one logical line => refactor to more speaking naming
    attr_accessor :expansion_stack, :remainders, :tokenization, :preprocessing, :parsing, :context_branches

    def initialize(program)
      @expansion_stack = [ program ]
      @remainders = {}
      @tokenization = { :recent_token => nil, :ongoing_comment => nil, :remainder => nil, :line_offset => 0 }
      @preprocessing = { :macros => {}, :conditional_stack => [], :line_directive => nil } # todo: move conditional_stack out of preprocessing hash

      # TODO: following attributes are not yet taken into account properly in the other functions.
      @parsing = { typedefs: {} }
      @context_branches = [ { conditions: [], unbound_objects: [], grammar_stack: [ Ooccor::CodeObjects::GroTranslationUnit.new(nil) ] } ] # fixme: origin of translation unit
    end

    def initialize_copy(orig)
      @remainders = @remainders.dup
      @tokenization = @tokenization.dup
      @preprocessing = @preprocessing.dup
    end

    # fixme: refactor (progress_file ?!)
    def end_of_file

      @tokenization[:recent_token] = nil 
      @preprocessing[:line_directive] = nil
      @preprocessing[:macros].clear

      unless @remainders.empty? and
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

end # module Ooccor
