# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/code_elements/char_represented/tokens/token.rb'

module Rocc::CodeElements::CharRepresented::Tokens

  # forward declarations
  class TknPpDirective   < CeToken;          end
  class TknPpInclude     < TknPpDirective;   end
  class TknPpDefine      < TknPpDirective;   end
  class TknPpUndef       < TknPpDirective;   end
  class TknPpError       < TknPpDirective;   end
  class TknPpPragma      < TknPpDirective;   end
  class TknPpLine        < TknPpDirective;   end
  class TknPpConditional < TknPpDirective;   end
  class TknPpCondIf      < TknPpConditional; end
  class TknPpCondElif    < TknPpConditional; end
  class TknPpCondElse    < TknPpConditional; end
  class TknPpCondEndif   < TknPpConditional; end


  class TknPpDirective < CeToken
    @PICKING_REGEXP = /^#\s*\w+/
    SUBCLASSES = [ TknPpInclude, TknPpConditional, TknPpDefine, TknPpUndef, TknPpError, TknPpPragma, TknPpLine ] # fixme(?): use `inherited' hook ?

    def self.pick!(env)
      if self != TknPpDirective
        # allow subclasses to call superclasses method implementation
        super
      else
        if self.pick_string(env) then
          tkn = nil
          if SUBCLASSES.find {|c| tkn = c.pick!(env)} then
            tkn
          else
            raise "Unknown preprocessor directive @#{env.expansion_stack.last.to_s}: `#{env.tokenization[:remainder]}'"
          end
        end
      end
    end # pick!

    # override Token's default implementation and throw exception (no pp directive shall be added to list of pending tokens)
    def pursue_branch(compilation_context, branch)
      raise 'not yet implemented'
    end
    
  end # class TknPpDirective


  class TknPpInclude < TknPpDirective

    @PICKING_REGEXP = /^#\s*include\s*(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*(?<file>(<|").*?(>|"))/ # fixme: not capable of handling `#include "foo\"bar"' or `#include <foo\>bar>'

    attr_reader :file

    def self.pick(env, str = nil, tknclass = nil)

      tkn = super

      if tkn
        # fixme: super just did match the @PICKING_REGEXP, and we match it here a second time.
        tkn.text =~ @PICKING_REGEXP

        tkn.file = $~[:file]
        comments = $~[:comments]

        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `include' and file name
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        while not comments.strip!.empty? do
          TknComment.pick!(env, comments)
        end
        
      end

      tkn

    end # pick

    def pursue_branch(compilation_context, branch)

      session = Session.current_session 
      tu = compilation_context.translation_unit
      
      path = session.find_include_file(@file, branch.current_dir)

      ce_file = session.ce_file(path)

      pctx = Rocc::Contexts::ParsingContext.new(compilation_context, branch)
      ce_file.pursue(pctx)
      
      tu.add_include_file(ce_file)
      
      raise 'not yet implemented'
    end

    # fixme: make protected
    attr_writer :file

  end # class TknPpInclude


  class TknPpDefine < TknPpDirective

    @PICKING_REGEXP = /^#\s*define\s*?(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*?(?<name>[A-Za-z_]\w*)(?<args>\(.*?\))?/

    attr_reader :name, :args

    def self.pick(env, str = nil, tknclass = nil)

      tkn = super

      if tkn
        # fixme: super just did match the @PICKING_REGEXP, and we match it here a second time.
        tkn.text =~ @PICKING_REGEXP

        tkn.name = $~[:name]
        comments = $~[:comments]
        args     = $~[:args]

        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `define' and macro name
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        while not comments.strip!.empty? do
          TknComment.pick!(env, comments)
        end
        
        tkn.args = if args
                     args[ 0] = ""
                     args[-1] = ""
                     args.split(/\s*,\s*/)
                   end

      end

      tkn

    end # pick


    def expand(env)

      macros = env.preprocessing[:macros]
      if macros.key? @name then
        macros[@name] << self
      else
        macros[@name] = [self]
      end

      env.preprocessing.freeze
      env.preprocessing = env.preprocessing.dup

    end # expand

    def tokens
      line_tokens = origin(LogicLine).tokens
      own_index = line_tokens.index(self)
      line_tokens[own_index+1..-1]
    end

    # fixme: make protected
    attr_writer :name, :args

  end # class TknPpDefine

  class TknPpUndef < TknPpDirective
    @PICKING_REGEXP = /^#\s*undef\s+/

    def expand(env)

      raise "invalid syntax" unless successor.is_a? TknWord # fixme: provide appropriate exception

      macros = env.preprocessing[:macros]
      if macros.key? successor.text then
        macros[successor.text] << self
      else
        macros[successor.text] = [self]
      end

      env.preprocessing.freeze
      env.preprocessing = env.preprocessing.dup

    end # expand

  end # class TknPpUndef

  class TknPpError < TknPpDirective
    @PICKING_REGEXP = /^#\s*error\s+.*/  
    def expand(env)
      # remove `#error' from @text
      @text.slice!(/#\s*error\s+/)
      # raise "pp#error: `#{@text}'" if FALSE # todo ??
    end
  end # class TknPpError

  class TknPpPragma < TknPpDirective
    @PICKING_REGEXP = /^#\s*pragma\s+.*/
    def expand(env)
      warn "ignoring #{origin.list}: `#{@text}' "
    end
  end # class TknPpPragma

  class TknPpLine < TknPpDirective

    @PICKING_REGEXP = /^#\s*line\s+/

    def expand(env)

      raise "invalid syntax" unless successor.is_a? TknNumber # fixme: provide appropriate exception
      @number = Integer(successor.text)

      if successor.successor
        raise "invalid syntax" unless successor.is_a? TknStringLitral # fixme: provide appropriate exception
        @filename = successor.successor.text.dup
        @filename[ 0] = ""
        @filename[-1] = ""
      end

      env.preprocessing[:line_directive] = self

      env.preprocessing.freeze
      env.preprocessing = env.preprocessing.dup

    end # expand

  end # class TknPpLine

  class TknPpConditional < TknPpDirective
    @PICKING_REGEXP = /^#\s*(if(n?def)?|elif|else|endif)\s+/

    SUBCLASSES = [ TknPpCondIf, TknPpCondElif, TknPpCondElse, TknPpCondEndif ] # fixme(?): use `inherited' hook ?

    def self.pick!(env)
      if self != TknPpDirective
        # allow subclasses to call superclasses method implementation
        super
      else
        if str = self.pick_string(env) then
          tkn = nil
          if SUBCLASSES.find {|c| tkn = c.pick!(env)} then
            tkn
          else
            raise StandardError, "Error processing preprocessor directive, not accepted by subclasses @#{origin.list}: `#{str}'"
          end
        end
      end
    end # pick!
    
    def expand(env)
      env.preprocessing.freeze
      env.preprocessing = env.preprocessing.dup
    end

  end # class TknPpConditional

  class TknPpCondIf < TknPpConditional
    @PICKING_REGEXP = /^#\s*if(n?def)?\s+/
    attr_reader :dependants

    def expand(env)
      @dependants = { TknPpCondIf => self }
      env.preprocessing[:conditional_stack] << self
      super
    end

    def summarize(given = [])
      result = []
      result << self if not given.include? self
      result
    end

  end # class

  class TknPpCondElif < TknPpConditional
    @PICKING_REGEXP = /^#\s*elif\s+/

    def expand(env)

      @dependants = env.preprocessing[:conditional_stack].last.dependants
      if @dependants.key? TknPpCondElif then
        @dependants[TknPpCondElif] << self
      else
        @dependants[TknPpCondElif] = [self]
      end

      env.preprocessing[:conditional_stack].pop
      env.preprocessing[:conditional_stack] << self
      super

    end # expand

    def summarize(given = [])
      result = @dependants[TknPpCondIf].summarize(given)
      @dependants[TknPpCondElif].each do |elif|
        result << elif if not given.include? elif
        break if elif.equal? self
      end
    end

  end # class

  class TknPpCondElse < TknPpConditional
    @PICKING_REGEXP = /^#\s*else\s+/

    def expand(env)
      raise "invalid syntax: multiple #else" if @dependants.key? TknPpCondElse # fixme: provide appropriate exception
      
      @dependants = env.preprocessing[:conditional_stack].last.dependants
      @dependants[TknPpCondElse] = self

      env.preprocessing[:conditional_stack].pop
      env.preprocessing[:conditional_stack] << self
      super

    end # expand

    def summarize(given = [])
      result = @dependants[TknPpCondElif].last.summarize
      result << self if not given.include? self
    end

  end # class

  class TknPpCondEndif < TknPpConditional
    @PICKING_REGEXP = /^#\s*endif\s+/

    def expand(env)

      tkn_if = env.preprocessing[:conditional_stack].pop

      @dependants = tkn_if.dependants
      @dependants[TknPpCondEndif] = self

      super

    end # expand

  end # class

end # module Rocc::CodeElements::CharRepresented::Tokens
