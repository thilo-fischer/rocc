# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects

  require 'ooccor/code_objects/code_object'

  # forward declarations
  class CoFile < CodeObject; end

  require 'ooccor/code_objects/tokens/tokens'

  class CoPhysicLine < CodeObject

    attr_reader :origin_offset
    alias index origin_offset

    attr_reader :line_directive

    def initialize(origin, text, origin_offset)
      super origin
      @origin_offset = origin_offset
      @text = text
      @line_directive = nil
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
          @origin.list(format) + ":" + line_number.to_s
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

         logic_line = CoLogicLine.new(origin, text).expand(env)

         @line_directive = logic_line.preprocessing[:line_directive]

       end

       env.expansion_stack.pop

     end # expand

     protected

     @ORIGIN_CLASS = CoFile

   end # class CoPhysicLine



   class CoLogicLine < CodeObject
     attr_reader :preprocessing

     def initialize(origin, text)
       super CoContainer.new(origin)
       @text = text
       @tokens = nil
       @preprocessing = nil
     end # initialize

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

 end # module Ooccor::CodeObjects
