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

require 'rocc/semantic/macro'
require 'rocc/semantic/macro_definition'

# for include directive
require 'rocc/contexts/lineread_context'
require 'rocc/contexts/comment_context'
require 'rocc/contexts/compilation_context'

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
  class TknNonautonomousPpConditional < TknPpConditional; end
  class TknPpCondElif    < TknNonautonomousPpConditional; end
  class TknPpCondElse    < TknNonautonomousPpConditional; end
  class TknPpCondEndif   < TknNonautonomousPpConditional; end


  class TknPpDirective < CeToken
    @PICKING_REGEXP = /^#\s*\w+/
    SUBCLASSES = [ TknPpInclude, TknPpConditional, TknPpDefine, TknPpUndef, TknPpError, TknPpPragma, TknPpLine ] # fixme(?): use `inherited' hook ?

    def self.pick!(tokenization_context)
      if self != TknPpDirective
        # allow subclasses to call superclass' method implementation
        super
      else
        if tokenization_context.remainder =~ @PICKING_REGEXP then
          tkn = nil
          if SUBCLASSES.find {|c| tkn = c.pick!(tokenization_context)} then
            tkn
          else
            raise "Unknown preprocessor directive @#{tokenization_context.remainder}'"
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

    def self.pick!(tokenization_context)

      tkn = super

      if tkn
        # fixme: super just did match the @PICKING_REGEXP, and we match it here a second time.
        tkn.text =~ @PICKING_REGEXP

        tkn.file = $~[:file]
        comments = $~[:comments]

        #warn "XXXX #{tkn.name_dbg} file: `#{tkn.file}' from `#{tkn.text}'"
        
        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `include' and file name
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        while not comments.strip!.empty? do
          TknComment.pick!(tokenization_context, comments)
        end
        
      end

      tkn

    end # pick

    # FIXME_R make private?
    def file=(arg)
      raise if @file
      @file = arg
    end

    def path
      @file[1..-2]
    end

    def quote
      if @file.start_with?('"') and @file.end_with?('"')
        :doublequote
      elsif @file.start_with?('<') and @file.end_with?('>')
        :anglebracket
      else
        raise # FIXME
      end
    end

    def pursue_branch(compilation_context, branch)
      current_dir = logic_line.first_physic_line.file.parent_dir
      path_abs = find_include_file(path, current_dir)
            
      file = compilation_context.fs_element_index.announce_element(Rocc::CodeElements::FileRepresented::CeFile, path_abs, self)
      compilation_context.translation_unit.add_include_file(file)

      lineread_context = Rocc::Contexts::LinereadContext.new(Rocc::Contexts::CommentContext.new(Rocc::Contexts::CompilationContext.new(compilation_context.translation_unit, compilation_context.fs_element_index, branch))) # FIXME
      file.pursue(lineread_context)
    end

    # TODO move to another, more appropriate class
    def find_include_file(path, current_dir)

      if path == File.absolute_path(path)
        # include directive gives absolute pathname
        path_abs = path
      else
        #warn "try to find `#{path}' for #{name_dbg}: will test #{File.absolute_path(path, current_dir.path_full)} if #{quote}==doublequote, include dirs are: `#{Rocc::Session::Session.current_session.include_dirs}'"
        if quote == :doublequote and File.exist?(File.absolute_path(path, current_dir.path_full))
          path_abs = File.absolute_path(path, current_dir.path_full)
        else
          session = Rocc::Session::Session.current_session
          dir = session.include_dirs.find {|d| File.exist?(File.absolute_path(path, d))}
          raise "Cannot find file included from #{self}: #{path}" unless dir
          path_abs = File.absolute_path(path, dir)
        end
      end

      path_abs
    end
    private :find_include_file

  end # class TknPpInclude


  class TknPpDefine < TknPpDirective
    # TODO the stuff picked here is more than a token, it is several tokens at once. same applies to (most of) the other preprocessor "token" classes handling preprocessor directives. technically fine, but calling it a token is missleading.
    @PICKING_REGEXP = /^#\s*define\s*?(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*?(?<identifier>[A-Za-z_]\w*)(?<parameters>\(.*?\))?/

    attr_reader :identifier, :comments, :parameters

    public # FIXME protect from write access from other classes, but allow write access from class methods
    #protected
    attr_writer :identifier, :comments, :parameters

    public
    def self.pick!(tokenization_context)

      tkn = super

      if tkn
        # XXX performance: super just did match the @PICKING_REGEXP, and we match it here a second time (redundantly).
        tkn.text =~ @PICKING_REGEXP

        tkn.identifier = $~[:identifier]
        
        comments   = $~[:comments]
        parameters = $~[:parameters]

        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `define' and macro identifier
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        # FIXME create comment objects
        #while not comments.strip!.empty? do
        #  TknComment.pick!(tokenization_context, comments)
        #end
        
        tkn.parameters = if parameters
                           parameters[ 0] = ""
                           parameters[-1] = ""
                           parameters.split(/\s*,\s*/)
                         end
      end

      tkn
    end # pick!


    def pursue_branch(compilation_context, branch)

      d = Rocc::Semantic::CeMacroDefinition.new(self)
      m = Rocc::Semantic::CeMacro.new(compilation_context.translation_unit, d, @identifier, @parameters)
      
      branch.announce_created_symbol(m)

      # XXX? Wouldn't it be sufficient (and more performant) to make
      # start/stop_collect_macro_tokens part of CompilationContext for
      # #define directive instead of CompilationBranch?
      # (open/close_token_request still needs to be part of
      # CompilationBranch for macro invokations though.)
      branch.start_collect_macro_tokens(m)
    end # pursue_branch

    def tokens
      line_tokens = origin(LogicLine).tokens
      own_index = line_tokens.index(self)
      line_tokens[own_index+1..-1]
    end

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
    def pursue_branch(compilation_context, branch)
      log.warn{"ignoring #{location}: `#{@text}' "}
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

    THIS_CLASS = TknPpConditional
    SUBCLASSES = [ TknPpCondIf, TknPpCondElif, TknPpCondElse, TknPpCondEndif ] # fixme(?): use `inherited' hook ?
    #@PICKING_REGEXP = /^#\s*(if(n?def)?|elif|else|endif)\b/ # TODO_R should not be necessary

    ##
    # +associated_cond_dirs+ array shared among all conditional
    # preprocessor directives that are associated with each other,
    # i.e. represent the same level of preprocessor branching. E.g. an
    # +#if+ directive along with two +#elif+ directives, a +#else+
    # directive and a +#endif+ directive which all belong
    # together. Stores references to all those TknPpConditional
    # objects that share the array.
    attr_reader :associated_cond_dirs

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @associated_cond_dirs = nil
    end

    def self.pick!(tokenization_context)
      if self != THIS_CLASS
        # allow subclasses to call superclass' method implementation
        super
      else
        tkn = nil
        SUBCLASSES.find {|c| tkn = c.pick!(tokenization_context)}
        tkn
      end
    end   
    
    def family_abbrev
      '#Cond'
    end
    
    def pursue_branch(compilation_context, branch)
      #warn "XXXX #{name_dbg}.pursue_branch(..., #{branch.name_dbg})"
      branch.announce_pp_branch(self)
    end

    ##
    # Add self to an associated_cond_dirs array and set up a reference
    # to that array.
    def associate(ppcond_directive)
      return if ppcond_directive.associated_cond_dirs.last == self # no need to associate if association was already established from another compilation_branch -- TODO smells
      #warn "XXXX #{name_dbg}.associate(#{ppcond_directive.name_dbg})"
      @associated_cond_dirs = ppcond_directive.associated_cond_dirs
      @associated_cond_dirs << self
    end

  end # class TknPpConditional

  # XXX_R? Make an inner module of class TknPpConditional?
  module PpConditionalMixin

    def negated_associated_conditions
      # negate conditions of all associated_cond_dirs except for the
      # last one because the last element in that array is self.
      raise unless @associated_cond_dirs.last == self # XXX remove
      @associated_cond_dirs[0..-2].inject(Rocc::Semantic::CeEmptyCondition.instance) do |conj, c|
        #warn "#{name_dbg}.negated_associated_conditions -> #{c.name_dbg}"
        conj.conjunction(c.condition.negate)
      end
    end
    private :negated_associated_conditions

  end # module PpConditionalMixin

  # XXX_R? Make an inner module of class TknPpConditional?
  module PpConditionalOwnConditionMixin
    include PpConditionalMixin
    
    attr_reader :condition_text
    
    def condition
      @condition ||= Rocc::Semantic::CeAtomicCondition.new(@condition_text, self)
    end
    
    # XXX_F if self would be the first element in @associated_cond_dirs, one could invoke inject similar as in negated_associated_conditions but without an argument to get collected_conditions
    def collected_conditions
      negated_associated_conditions.conjunction(condition)
    end

  end # module PpConditionalOwnConditionMixin

  class TknPpCondIf < TknPpConditional
    include PpConditionalOwnConditionMixin

    @PICKING_REGEXP = /^#\s*if(n?def)?\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
      # TknPpCondIf starts associated_cond_dirs array
      @associated_cond_dirs = [ self ]
    end

    def family_abbrev
      '#If'
    end
    
    def pursue_branch(compilation_context, branch)
      case text
      when /^#\s*if(?<negation>n)?def\s+(?<identifier>\w+)\s*$/,
           /^#\s*if\s*(\s|(?<negation>!))\s*defined\s*[\s\(]\s*(?<identifier>\w+)\s*[\s\)]\s*$/
        if $~[:negation]
          @condition_text = "!defined(#{$~[:identifier]})"
        else
          @condition_text = "defined(#{$~[:identifier]})"
        end
      when /^#\s*if\b(?<condition>.*)$/
        @condition_text = $~[:condition]
        @condition_text.strip!
      else
        raise "error while parsing #{origin.path_dbg}"
      end
      super
    end

  end # class TknPpCondIf

  class TknNonautonomousPpConditional < TknPpConditional
    def pursue_branch(compilation_context, branch)
      associate(branch.ppcond_stack.last)
      super
    end
  end # class TknNonautonomousPpConditional

  class TknPpCondElif < TknNonautonomousPpConditional
    include PpConditionalOwnConditionMixin

    @PICKING_REGEXP = /^#\s*elif\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
    end

    def family_abbrev
      '#Elif'
    end
    
    def pursue_branch(compilation_context, branch)
      case text
      when /^#\s*elif\s*(\s|(?<negation>!))\s*defined\s*[\s\(]\s*(?<identifier>\w+)\s*[\s\)]\s*$/
        if $~[:negation]
          @condition_text = "!defined(#{$~[:identifier]})"
        else
          @condition_text = "defined(#{$~[:identifier]})"
        end         
      when /^#\s*elif\b(?<condition>.*)$/
        @condition_text = $~[:condition]
        @condition_text.strip!
      else
        raise "error while parsing #{origin.path_dbg}"
      end
      super
    end

  end # class TknPpCondElif

  class TknPpCondElse < TknNonautonomousPpConditional
    include PpConditionalMixin

    @PICKING_REGEXP = /^#\s*else\b.*$/

    def family_abbrev
      '#Else'
    end
    
    # XXX substitute with unit test
    def pursue_branch(compilation_context, branch)
      raise "Programming error :(" unless text =~ /^#\s*else\s*$/
      super
    end

    def collected_conditions
      negated_associated_conditions
    end
    
  end # class TknPpCondElse

  class TknPpCondEndif < TknNonautonomousPpConditional
    @PICKING_REGEXP = /^#\s*endif\b.*$/

     def family_abbrev
      '#Endif'
    end
    
   # XXX substitute with unit test
    def pursue_branch(compilation_context, branch)
      raise "Programming error :(" unless text =~ /^#\s*endif\s*$/
      super
    end
    
  end # class TknPpCondEndif

end # module Rocc::CodeElements::CharRepresented::Tokens
