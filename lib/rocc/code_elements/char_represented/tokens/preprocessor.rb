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

require 'rocc/semantic/macro'
require 'rocc/semantic/macro_definition'

# for include directive
require 'rocc/contexts/lineread_context'
require 'rocc/contexts/comment_context'
require 'rocc/contexts/compilation_context'

module Rocc::CodeElements::CharRepresented

  # forward declarations
  class CeCharObject < Rocc::CodeElements::CodeElement; end
  class CeCoPpDirective   < CeCharObject;     end
  class CeCoPpInclude     < CeCoPpDirective;   end
  class CeCoPpDefine      < CeCoPpDirective;   end
  class CeCoPpUndef       < CeCoPpDirective;   end
  class CeCoPpError       < CeCoPpDirective;   end
  class CeCoPpPragma      < CeCoPpDirective;   end
  class CeCoPpLine        < CeCoPpDirective;   end
  class CeCoPpConditional < CeCoPpDirective;   end
  class CeCoPpCondIf      < CeCoPpConditional; end
  class CeCoPpCondNonautonomous < CeCoPpConditional; end
  class CeCoPpCondElif    < CeCoPpCondNonautonomous; end
  class CeCoPpCondElse    < CeCoPpCondNonautonomous; end
  class CeCoPpCondEndif   < CeCoPpCondNonautonomous; end


  # FIXME_R handling of comments interfering with pp directives

  class CeCoPpDirective < CeCharObject
    @REGEXP = /#\s*\w+/
    @PICKING_DELEGATEES = [
      CeCoPpInclude,
      CeCoPpConditional,
      CeCoPpDefine,
      CeCoPpUndef,
      CeCoPpError,
      CeCoPpPragma,
      CeCoPpLine
    ]

    # override Token's default implementation and throw exception (no
    # pp directive shall be added to list of pending tokens)
    def pursue_branch(compilation_context, branch)
      raise 'not yet implemented'
    end
    
  end # class CeCoPpDirective


  class CeCoPpInclude < CeCoPpDirective

    @REGEXP = /#\s*include\s*(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*(?<file>(<|").*?(>|"))/ # XXX_R not capable of handling `#include "foo\"bar"' or `#include <foo\>bar>'

    attr_reader :file

    def self.pick!(tokenization_context)

      tkn = super

      if tkn
        # TODO_F(pick_captures) Super just did match the @PICKING_REGEXP, and we match it here a second time (redundantly). Consider returning Regexp.last_match in CharObject.peek and CharObject.pick_string! and passing Regexp.last_match.named_captures to the CharObject.create. (=> same performance?)
        tkn.text =~ picking_regexp

        tkn.file = $~[:file]
        comments = $~[:comments]

        #warn "XXXX #{tkn.name_dbg} file: `#{tkn.file}' from `#{tkn.text}'"
        
        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `include' and file name
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        while not comments.strip!.empty? do
          CeCoComment.pick!(tokenization_context, comments)
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
      # strip quote characters
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

  end # class CeCoPpInclude


  class CeCoPpDefine < CeCoPpDirective
    # TODO the stuff picked here is more than a token, it is several tokens at once. same applies to (most of) the other preprocessor "token" classes handling preprocessor directives. technically fine, but calling it a token is missleading.
    @REGEXP = /#\s*define\s*?(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*?(?<identifier>[A-Za-z_]\w*)(?<parameters>\(.*?\))?/

    attr_reader :identifier, :comments, :parameters

    public # FIXME protect from write access from other classes, but allow write access from class methods
    #protected
    attr_writer :identifier, :comments, :parameters

    public

    # XXX_R mostly redundant to CeCoPpInclude.pick!
    def self.pick!(tokenization_context)

      tkn = super

      if tkn
        # TODO_F(pick_captures)
        tkn.text =~ picking_regexp

        tkn.identifier = $~[:identifier]
        
        comments   = $~[:comments]
        parameters = $~[:parameters]

        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `define' and macro identifier
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        # FIXME create comment objects
        #while not comments.strip!.empty? do
        #  CeCoComment.pick!(tokenization_context, comments)
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

  end # class CeCoPpDefine

  class CeCoPpUndef < CeCoPpDirective
    @REGEXP = /^#\s*undef\s+/

    def pursue_branch(compilation_context, branch)
      raise "invalid syntax" unless successor.is_a? TknWord # fixme: provide appropriate exception
      raise "not yet supported"
    end # pursue_branch

  end # class CeCoPpUndef

  class CeCoPpError < CeCoPpDirective
    @REGEXP = /^#\s*error\s+.*/  

    # TODO_W
    def pursue_branch(compilation_context, branch)
      # remove `#error' from @text
      @text.slice!(/#\s*error\s+/)
      raise "pp#error: `#{@text}'"
    end
    
  end # class CeCoPpError

  class CeCoPpPragma < CeCoPpDirective
    @REGEXP = /^#\s*pragma\s+.*/
    
    def pursue_branch(compilation_context, branch)
      log.warn{"ignoring #{location}: `#{@text}' "}
    end
    
  end # class CeCoPpPragma

  class CeCoPpLine < CeCoPpDirective

    @REGEXP = /^#\s*line\s+/

    def pursue_branch(compilation_context, branch)
      raise "not yet supported"
    end # pursue_branch

    #def expand(env)
    #
    #  raise "invalid syntax" unless successor.is_a? TknNumber # fixme: provide appropriate exception
    #  @number = Integer(successor.text)
    #
    #  if successor.successor
    #    raise "invalid syntax" unless successor.is_a? TknStringLitral # fixme: provide appropriate exception
    #    @filename = successor.successor.text.dup
    #    @filename[ 0] = ""
    #    @filename[-1] = ""
    #  end
    #
    #  env.preprocessing[:line_directive] = self
    #
    #  env.preprocessing.freeze
    #  env.preprocessing = env.preprocessing.dup
    #
    #end # expand

  end # class CeCoPpLine

  class CeCoPpConditional < CeCoPpDirective

    @PICKING_DELEGATEES = [ CeCoPpCondIf, CeCoPpCondElif, CeCoPpCondElse, CeCoPpCondEndif ]
    @REGEXP = /^#\s*(if(n?def)?|elif|else|endif)\b/

    ##
    # +associated_cond_dirs+ array shared among all conditional
    # preprocessor directives that are associated with each other,
    # i.e. represent the same level of preprocessor branching. E.g. an
    # +#if+ directive along with two +#elif+ directives, a +#else+
    # directive and a +#endif+ directive which all belong
    # together. Stores references to all those CeCoPpConditional
    # objects that share the array.
    attr_reader :associated_cond_dirs

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @associated_cond_dirs = nil
    end
    
    FAMILY_ABBREV = '#Cond'
    def self.family_abbrev
      FAMILY_ABBREV
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

  end # class CeCoPpConditional

  # XXX_R? Make an inner module of class CeCoPpConditional?
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

  # XXX_R? Make an inner module of class CeCoPpConditional?
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

  class CeCoPpCondIf < CeCoPpConditional
    include PpConditionalOwnConditionMixin

    @REGEXP = /^#\s*if(n?def)?\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
      # CeCoPpCondIf starts associated_cond_dirs array
      @associated_cond_dirs = [ self ]
    end

    FAMILY_ABBREV = '#If'
    def self.family_abbrev
      FAMILY_ABBREV
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

  end # class CeCoPpCondIf

  class CeCoPpCondNonautonomous < CeCoPpConditional
    def pursue_branch(compilation_context, branch)
      associate(branch.ppcond_stack.last)
      super
    end
  end # class CeCoPpCondNonautonomous

  class CeCoPpCondElif < CeCoPpCondNonautonomous
    include PpConditionalOwnConditionMixin

    @REGEXP = /^#\s*elif\b.*$/

    def initialize(origin, text, charpos, whitespace_after = '', direct_predecessor = nil)
      super
      @condition_text = nil
    end

    FAMILY_ABBREV = '#Elif'
    def self.family_abbrev
      FAMILY_ABBREV
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

  end # class CeCoPpCondElif

  class CeCoPpCondElse < CeCoPpCondNonautonomous
    include PpConditionalMixin

    @REGEXP = /^#\s*else\b.*$/

    FAMILY_ABBREV = '#Else'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    # XXX substitute with unit test
    def pursue_branch(compilation_context, branch)
      raise "Programming error :(" unless text =~ /^#\s*else\s*$/
      super
    end

    def collected_conditions
      negated_associated_conditions
    end
    
  end # class CeCoPpCondElse

  class CeCoPpCondEndif < CeCoPpCondNonautonomous
    @REGEXP = /^#\s*endif\b.*$/

    FAMILY_ABBREV = '#Endif'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
   # XXX substitute with unit test
    def pursue_branch(compilation_context, branch)
      raise "Programming error :(" unless text =~ /^#\s*endif\s*$/
      super
    end
    
  end # class CeCoPpCondEndif

end # module Rocc::CodeElements::CharRepresented::Tokens
