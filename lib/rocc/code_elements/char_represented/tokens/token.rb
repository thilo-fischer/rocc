# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeObjects::Tokens

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
    attr_reader :text, :charpos, :direct_predecessor, :direct_successor

    PICKING_ORDER = [ TknWord, TknStringLiteral, TknNumber, TknComment, Tkn3Char, Tkn2Char, Tkn1Char ]

    def initialize(text, origin, charpos, whitespace_after = "", direct_predecessor = nil)
      super origin

      @text = text
      @charpos = charpos
      @whitespace_after = ""
      @direct_predecessor = direct_predecessor
    end # initialize

    def announce
      # Don't want to register tokens, they can be referenced from the content of CoLogicLine.
      nil
    end

    ##
    # string to represent this element in rocc debugging and internal error messages
    def name_dbg
      "Tkn[" + @text + "]"
    end

    ##
    # string to represent this element in messages from rocc
    def name
      "`" + @text + "' token"
    end

    ##
    # character(s) to use to separate this element from its origin in path information
    def path_separator
      ":" + @charpos + " > "
    end
    

    ##
    # If the to be tokenized string in ctx begins with a token of this
    # class, return the according section of that string which
    # represents the token. Else, return nil.
    def self.pick_string(ctx)
      # find regexp in string
      # return part of string matching regexp 
      str = ctx.remainder.slice(@PICKING_REGEXP)
      dbg "found " + path if str
      str
    end # pick_string


    ##
    # If the to be tokenized string in ctx begins with a token of this
    # class, mark the according section of that string which
    # represents the token as tokenized and return that section. Else,
    # return nil.
    def self.pick_string!(ctx)
      # find regexp in string
      # remove part of string matching regexp
      # return part of string matching regexp
      str = ctx.remainder.slice!(@PICKING_REGEXP)
      dbg "found " + path if str
      str
    end # pick_string!

    ##
    # If the to be tokenized string in ctx begins with a token of this
    # class, create and return an instance of this class from that
    # section; does not mark the section as being tokenized.  Else,
    # return nil.
    #
    # If parameter str is given, create and return an instance of this
    # class from that string (ignoring ctx). # FIXME smells ...
    def self.pick(ctx, str = nil)
      str ||= self.pick_string(ctx)
      if str then
        whitespace_after = ctx.lstrip
        create(ctx, str, whitespace_after)
      end

    end # pick

    ##
    # If the to be tokenized string in ctx begins with a token of this
    # class, mark the according section in string as tokenized and
    # create and return an instance of this class from that section.
    # Else, return nil.
    def self.pick!(ctx)
      str = self.pick_string!(ctx)
      if str
        whitespace_after = ctx.lstrip
        create(ctx, str, whitespace_after)
      end
    end # pick!

    ##
    # Create token of this class from and within the given context.
    def self.create(tkn_ctx, text, whitespace_after = "")
      pred = tkn_ctx.recent_token
      new_tkn = new(text, tkn_ctx.line, tkn_ctx.charpos, whitespace_after, pred)
      pred.direct_successor = new_tkn if pred
      tkn_ctx.add_token(new_tkn)
    end

    def pursue(cc_ctx)
      cc_ctx.context_branches.each {|ctx_br| pursue(ctx_br)}
    end
    
    def pursue_branch(ctx_branch)
      ctx_branch.unbound_objects << self
    end

    # skips TknComments etc.
    def effective_predecessor
      case direct_predecessor
      when TknComment
        direct_predecessor.effective_predecessor
      when TknPpDirInclude
        raise "Not yet supported"
      # FIXME what about macro expansion?
      else
        direct_predecessor
      end
    end


    # skips TknComments etc.
    def effective_successor
      raise "not yet supported, see effective_predecessor"
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

end # module Rocc::CodeObjects::Tokens
