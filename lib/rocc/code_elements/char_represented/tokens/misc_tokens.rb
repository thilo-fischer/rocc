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

require 'rocc/semantic/specification'

module Rocc::CodeElements::CharRepresented::Tokens

  class TknWord < CeToken
    # one word-charcter that is no digit
    # followed by an arbitrary number of word-charcters or digits
    @PICKING_REGEXP = /^[A-Za-z_]\w*\b/

    def self.pick!(env)
      if self != TknWord
        # allow subclasses to call superclasses method implementation
        # FIXME smells
        super
      else
        # FIXME handle macros named like keywords
        if pick_string(env) then
          TknKeyword.pick!(env) || TknIdentifier.pick!(env)
        end
      end
    end # pick!
    
    def pursue_branch(compilation_context, branch)
      @symbols = branch.find_symbols(@text)
      @symbols.each do |s|
        case s.family
        when CeMacro
          if s.conditions > branch.conditions
            subbranch = branch.branch_out(s.conditions - branch.conditions)
            mexp = CeMacroExpansion.new(self, s)
            mexp.pursue_branch(compilation_context, subbranch)
          else
            mexp = CeMacroExpansion.new(self, s)
            mexp.pursue_branch(compilation_context, branch)
          end
        #when CeTypedef
        else
          super
        end
      end
    end # pursue_branch

  end # class TknWord

  class TknIdentifier < TknWord
  end # class TknIdentifier

  class TknIntegerLiteral < CeToken
    @PICKING_REGEXP = Regexp.union(/^[+-]?\d+[ul]*\b/i, /^[+-]?0x(\d|[abcdef])+[ul]*\b/i)
    
    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
  end # class TknIntegerLiteral

  class TknFloatLiteral < CeToken
    # C99 allows hex float literals
    @PICKING_REGEXP = Regexp.union(/^[+-]?(\d+\.|\.\d)\d*(e[+-]?\d+)?\b/i, /^[+-]?((\d|[abcdef])+\.|\.(\d|[abcdef]))(\d|[abcdef])*p[+-]?\d+\b/i)

    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
  end # class TknFloatLiteral

  class TknCharLiteral < CeToken
    @PICKING_REGEXP = Regexp.union(/^L'.'/, /^L'\\(['"?\\abfnrtv]|[01234567]+|[xuU](\d|[AaBbCcDdEeFf])+)'/)
    
    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
  end # class TknCharLiteral

  class TknStringLiteral < CeToken
    # an optional 'L' followed by
    # a double quote
    # optionally followed by
    # an arbitrary number of arbitrary characters (non-greedy)
    # where the last character is no backslash
    # followed by a double quote
    @PICKING_REGEXP = /^L?"(.*?[^\\])?"/

    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
  end # class TknStringLiteral

  class Tkn3Char < CeToken
    # <<=, >>=, ...
    @PICKING_REGEXP = /^((<<|>>)=|\.\.\.)/
  end

  class Tkn2Char < CeToken
    @PICKING_REGEXP = /^([+\-*\/%=!&|<>\^]=|<<|>>|##)/
  end

  class Tkn1Char < CeToken
    
    @PICKING_REGEXP = /^[+\-*\/%=!&|<>\^,:;?()\[\]{}~#]/

    def pursue_branch(compilation_context, branch)
      # FIXME refactor: split into smaller functions

      case @text
      when ","
        case branch.arising
        when Specification, Definition
          raise "TODO finalize specification, start next specification"
        end
        
        case branch.current_scope
        when nil
          raise "syntax error or not yet supported"
        when Rocc::Semantic::FunctionSignature
          if branch.arising.is_a? FunctionParameter
            raise "TODO"
          else
            raise "programming error"
          end
        end
        
      when ";"
        case branch.arising
        when nil
          # do nothing
          
        when ArisingDefinition
          definition = Definition.new(branch.arising.origin)
          known_symbol = branch.find_symbol(identifier, namespace, branch.arising.symbol_family) # FIXME conditions # TODO linkage?
          case known_symbol.count
          when 0
            symbol = branch.arising.symbol_family.new([definition], identifier)
            branch.announce_symbol(symbol)
          when 1
            symbol = symbol.first
            symbol.add_specification(definition)
          else
            raise "programming error"
          end
        when ArisingSpecification
          declaration = Declaration.new(branch.arising.origin)
          known_symbol = branch.find_symbol(identifier, namespace, branch.arising.symbol_family) # FIXME conditions # TODO linkage?
          case known_symbol.count
          when 0
            symbol = branch.arising.symbol_family.new([definition], identifier)
          when 1
            symbol = symbol.first
            symbol.add_specification(definition)
            branch.announce_symbol(symbol)
          else
            raise "programming error"
          end
        else
          raise "not yet supported, #{branch.arising.inspect}"
        end
        branch.clear_arising
        
      when "("
        if branch.has_pending?
          case branch.pending_tokens.last
          when TknIdentifier
            identifier = branch.pending_tokens.last.text
            if branch.current_scope.is_a?(CeTranslationUnit)
              if branch.arising == nil or branch.arising.is_a?(CeSpecification)
                functions = branch.find_symbol(identifier, :ordinary, CeFunction) # FIXME conditions # TODO linkage?
                case functions.count
                when 0
                  # new function, origin is empty array because Specification that adduces the function can only be instantiated when FunctionSignature is complete and we parse either ';' or '{' to determine whether to instantiate it as Declaration or Definition
                  function = CeFunction.new([], identifier)
                when 1
                  function = functions.first
                else
                  raise "programming error"
                end
                branch.enter_scope(Rocc::Semantic::FunctionSignature.new(function))
                branch.clear_arising
              end
              end
          when TknKwMisc
            if branch.pending_tokens.last.text == "sizeof"
              raise "not yet supported"
            end
          end
        else
          # XXX could also be a cast
          branch.enter_scope(CompoundExpression.new([self]))
        end
        
      when ")"
        case branch.current_scope
        when FunctionSignature
          raise "TODO"
        when CompoundExpression
          raise "TODO"
        else
          raise "syntax error or not yet supported"
        end

      when "{"
        case branch.arising
        when nil
          raise "not yet supported: start compound statement"
          
        when ArisingDefinition, ArisingSpecification
          raise "syntax error or not yet supported" unless branch.arising.symbol_familiy < CoFunction
          definition = Definition.new(branch.arising.origin, function_signature)
          known_symbol = branch.find_symbol(identifier, :ordinary, CoFunction) # FIXME conditions # TODO linkage?
          case known_symbol.count
          when 0
            symbol = CoFunction.new([definition], identifier)
            branch.announce_symbol(symbol)
          when 1
            symbol = symbol.first
            symbol.add_specification(definition)
          else
            raise "programming error"
          end
        else
          raise "not yet supported, #{branch.arising.inspect}"
        end
        branch.clear_arising
        
      else
        super
      end
  
    end # pursue_branch 

    def expand_with_context(env, ctxt)

      dbg "#{self}.expand_with_context" # at `#{ctxt.inspect}'"

      unbound = ctxt[:unbound_objects]
      grast = ctxt[:grammar_stack]

      case @text

      when ","
        case grast.last
        when GroTranslationUnit, GroCompoundStatement
          GroDeclaration.wrap_up(env, ctxt)
        when GroDeclaration
          grast.last.add_declarator(env, ctxt)
        when GroEnumeratorList
          raise "todo"
        else
          super
        end

      when ";"
        case grast.last
        when GroTranslationUnit
          GroDeclaration.wrap_up(env, ctxt)
          grast.last.finalize(env, ctxt)
        when GroDeclaration
          grast.last.add_declarator(env, ctxt)
          grast.last.finalize(env, ctxt)
        when GroCompoundStatement
          # declaration or statement
          GroStatement.pick!(env, ctxt) # fixme: handle declarations properly
        when GroControlStructure
          # statement
          raise "todo"
        when GroParenthesized
          # expression-list in for-loop
          if grast[-2].is_a? GroControlStructure and grast[-2].origin[0].text == "for" # fixme
            super # fixme
          else
            raise
          end
        when GroStructDeclarationList
          raise "todo"
        else
          raise
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          env.context.delete(ctx)
          nil
        end

      when "{"
        case grast.last
        when GroTranslationUnit, GroCompoundStatement

          if tagged_declaration_list = GroTaggedDeclarationList.pick!(env, ctxt)
            grast << tagged_declaration_list

          elsif grast.last.is_a? GroTranslationUnit
            # function definition
            function_definition = GroFunctionDefinition.pick!(env, ctxt)
            raise "assertion" unless function_definition
            grast << function_definition
            grast << GroCompoundStatement.new(self, function_definition)

          elsif grast.last.is_a? GroCompoundStatement and unbound.empty?
            # GroCompoundStatement
            grast << GroCompoundStatement.new(self, grast.last)

          else
            raise

          end
            
        when GroControlStructure
          statement = GroCompoundStatement.new(self, grast.last)
          grast.last.add_statement(statement)
          grast << statement

        else
          raise
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          env.context.delete(ctx)
          nil
        end

      when "("
        grast << GroParenthesized.new(self, grast.last)

      when "["
        grast << GroBracketed.new(self, grast.last)

      when ")", "}", "]"
        case grast.last
        when GroParenthesized, GroBracketed, GroTaggedDeclarationList
          grast.last.finalize(env, ctxt, self)
        when GroCompoundStatement
          grast.last.finalize(env, ctxt, self)
          case grast.last
          when GroFunctionDefinition
            grast.last.finalize(env, ctxt)  
          when GroCompoundStatement
            # do nothing
          else
            raise
          end

        else
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          env.context.delete(ctx)
          nil
         
        end

      else
        super
      end

      ctxt

    end # expand_with_context   
    
  end # Tkn1Char

end # module Rocc::CodeElements::CharRepresented::Tokens
