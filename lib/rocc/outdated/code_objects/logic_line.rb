# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeObjects

  require 'rocc/code_objects/code_object'

  # forward declarations
  class CoFile < CodeObject; end

  require 'rocc/code_objects/tokens/tokens'
  
  
  class CoLogicLine < CodeObject
    attr_reader :preprocessing

    def initialize(origin, text)
      super CoContainer.new(origin)
      @text = text
      @tokens = nil
      @preprocessing = nil
    end # initialize

    def announce
      # Don't want to register lines, they can be referenced from the content of ... are they? (fixme)
      nil
    end

    def expand(env)
      env.expansion_stack.push self
      @preprocessing = env.preprocessing
      tokenize(env).map {|t| t.expand(env)}
      env.expansion_stack.pop
    end # expand

    def tokens
      raise "#{to_s} has not yet been tokenized." unless @tokens
      @tokens
    end

    alias content tokens

    def conditions
      result = []
      @preprocessing[:conditional_stack].each do |cond|
        result << cond.summarize
      end
    end
    
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
        tkn = Tokens::TknMultiLineBlockComment.pick!(env)
        @tokens << tkn if tkn
      end

      # remove leading and trailing whitespace
      remainder.rstrip!
      env.tokenization[:line_offset] += remainder.slice!(/^\s*/).length

      # handle comments interfering with preprocessor directives
      while tkn = Tokens::TknComment.pick!(env)
        @tokens << tkn if tkn
      end
      return @tokens if remainder.empty?
      if remainder[0] == "#" then
        remainder[0] = ""
        env.tokenization[:line_offset] += remainder.slice!(/^\s*/).length
        while tkn = Tokens::TknComment.pick!(env)
          @tokens << tkn if tkn
        end    
        remainder.prepend "#"
      end

      # handle preprocessor directives
      tkn = Tokens::TknPpDirective.pick!(env)
      @tokens << tkn if tkn

      until remainder.empty? do
        if Tokens::CoToken::PICKING_ORDER.find {|c| tkn = c.pick!(env)}
          @tokens << tkn
        else
          raise "Could not dertermine next token in `#{remainder}'"
        end
      end
      
      @tokens

    end # tokenize

  end # class CoLogicLine

end # module Rocc::CodeObjects
