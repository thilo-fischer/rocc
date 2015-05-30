# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Ooccor::CodeObjects

  require 'ooccor/code_objects/grammar/grammar'

  module Tokens

    # forward declarations

    class CoToken          < CodeObject; end
    class TknComment       < CoToken;    end
    class TknPreprocessor  < CoToken;    end
    class TknWord          < CoToken;    end
    class TknStringLiteral < CoToken;    end
    class TknNumber        < CoToken;    end
    class Tkn3Char         < CoToken;    end
    class Tkn2Char         < CoToken;    end
    class Tkn1Char         < CoToken;    end


    class CoToken < CodeObject
      attr_reader :text, :origin_offset, :direct_predecessor, :direct_successor

      PICKING_ORDER = [ TknWord, TknStringLiteral, TknNumber, TknComment, Tkn3Char, Tkn2Char, Tkn1Char ]

      def initialize(env, text,
                     offset = env.tokenization[:line_offset],
                     origin = env.expansion_stack.last,
                     direct_predecessor = env.tokenization[:recent_token])

        super origin
        @origin_offset = offset

        @text = text

        @direct_predecessor = direct_predecessor
        @direct_predecessor.direct_successor = self if @direct_predecessor

      end # initialize

      def announce
        # Don't want to register tokens, they can be referenced from the content of CoLogicLine.
        nil
      end

      def to_s
        self.class.to_s + ":`" + @text + "'"
      end


      def self.pick_string(env)
        # find regexp in string
        # return part of string matching regexp 
        str = env.tokenization[:remainder].slice(@PICKING_REGEXP)
        dbg "found #{self.to_s} as `#{str}' @`#{env.tokenization[:remainder]}'" if str
        str
      end # pick_string


      def self.pick_string!(env, source = nil)
        #dbg "#{self.instance_variables}, #{self.class_variables}, #{self.constants}", 3
        source ||= env.tokenization[:remainder]
        # find regexp in string
        # remove part of string matching regexp
        # return part of string matching regexp
        str = env.tokenization[:remainder].slice!(@PICKING_REGEXP)
        dbg "found #{self.to_s}, removed `#{str}', left `#{source}'" if str
        str
      end # pick_string!


      def self.pick(env, str = nil, tknclass = nil)
        str ||= self.pick_string(env)
        tknclass ||= self

        if str then
          tkn = tknclass.new(env, str)
          env.progress_token(tkn, str.length)
          dbg "picked #{tkn.inspect}: `#{str}'" if tkn
          tkn
        end

      end # pick


      def self.pick!(env, source = nil)
        str = self.pick_string!(env, source)
        pick(env, str) if str
      end # pick!


      def expand(env)
        env.context_branches.each {|ctx| expand_with_context(env, ctx)}
      end
      
      def expand_with_context(env, ctxt)
        ctxt[:unbound_objects] << self
      end # expand_with_context


      # skips TknComments
      def predecessor
        if direct_predecessor.class.is_a? TknComment
          direct_predecessor.predecessor
        else
          direct_predecessor
        end
      end


      # skips TknComments
      def successor
        if direct_successor.class.is_a? TknComment
          direct_successor.successor
        else
          direct_successor
        end
      end

      def conditions
        origin(LogicLine).conditions
      end

      protected

#      @ORIGIN_CLASS = CoLogicLine

      def direct_successor=(s)
        @direct_successor = s
      end

      def self.picking_regexp # fixme
        @PICKING_REGEXP
      end

    end # CoToken

  end # module Tokens
end # module Ooccor::CodeObjects
