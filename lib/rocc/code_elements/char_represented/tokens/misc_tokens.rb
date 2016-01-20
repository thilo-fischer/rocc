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

require 'rocc/semantic/arising_specification'
require 'rocc/semantic/statement'
require 'rocc/semantic/expression'
require 'rocc/semantic/function'
require 'rocc/semantic/function_signature'

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

    def name_dbg
      "TknWord[#{@text}]"
    end
    
  end # class TknWord

  class TknIdentifier < TknWord
    @PICKING_REGEXP = /^[A-Za-z_]\w*\b/
    
    def pursue_branch(compilation_context, branch)

      if branch.has_arising?
        raise unless branch.arising.is_a? Rocc::Semantic::Temporary::ArisingSpecification
      else
        branch.arising = Rocc::Semantic::Temporary::ArisingSpecification.new(self)
      end

      branch.arising.identifier = @text
      
    end
    
    def name_dbg
      "TknIdent[#{@text}]"
    end
    
 end # class TknIdentifier

  class TknLiteral < CeToken
    def pursue_branch(compilation_context, branch)
      if branch.has_pending?
        super
      else
        case branch.current_scope
        when Rocc::Semantic::ExpressionMixin
          branch.current_scope.expression = Rocc::Semantic::AtomicExpression.new(branch.current_scope, self)
        end
      end
    end # pursue_branch
  end # class TknLiteral
  
  class TknIntegerLiteral < TknLiteral
    @PICKING_REGEXP = Regexp.union(/^[+-]?\d+[ul]*\b/i, /^[+-]?0x(\d|[abcdef])+[ul]*\b/i)
    
    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    def name_dbg
      "TknInt[#{@text}]"
    end
    
  end # class TknIntegerLiteral

  class TknFloatLiteral < TknLiteral
    # C99 allows hex float literals
    @PICKING_REGEXP = Regexp.union(/^[+-]?(\d+\.|\.\d)\d*(e[+-]?\d+)?\b/i, /^[+-]?((\d|[abcdef])+\.|\.(\d|[abcdef]))(\d|[abcdef])*p[+-]?\d+\b/i)

    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    def name_dbg
      "TknFloat[#{@text}]"
    end
    
  end # class TknFloatLiteral

  class TknCharLiteral < TknLiteral
    @PICKING_REGEXP = Regexp.union(/^L'.'/, /^L'\\(['"?\\abfnrtv]|[01234567]+|[xuU](\d|[AaBbCcDdEeFf])+)'/)
    
    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    def name_dbg
      "TknChar[#{@text}]"
    end
    
  end # class TknCharLiteral

  class TknStringLiteral < TknLiteral
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
    
    def name_dbg
      "TknStr[#{@text}]"
    end
    
  end # class TknStringLiteral

  # XXX rename: TknNChar => TknNPunktuationChar
  class Tkn3Char < CeToken
    # <<=, >>=, ...
    @PICKING_REGEXP = /^((<<|>>)=|\.\.\.)/
    def name_dbg
      "Tkn3Pkt[#{@text}]"
    end
  end

  class Tkn2Char < CeToken
    @PICKING_REGEXP = /^([+\-*\/%=!&|<>\^]=|<<|>>|##)/
    def name_dbg
      "Tkn2Pkt[#{@text}]"
    end
  end

  class Tkn1Char < CeToken
    
    @PICKING_REGEXP = /^[+\-*\/%=!&|<>\^,:;?()\[\]{}~#]/

    def pursue_branch(compilation_context, branch)
      # FIXME refactor: split into smaller functions

      case @text
         
      when ";"
        warn branch.scope_stack_trace
        raise "still pending: `#{branch.pending_to_s}'" if branch.has_pending?
        
        if branch.arising
          case branch.arising
          when Rocc::Semantic::Temporary::ArisingSpecification
            branch.arising.mark_as_declaration unless branch.arising.is_definition
            branch.finalize_arising
          else
            raise
          end
        else
          if branch.current_scope.complete?
            branch.leave_scope
          else
            raise
          end
        end
        
      when ","
        case branch.arising
            
        when nil
        # ...
          
        when Rocc::Semantic::Temporary::ArisingSpecification # remember: ArisingDefinition < ArisingSpecification
            
            next_specification = Rocc::Semantic::Temporary::ArisingSpecification.new([])
            next_specification.linkage = branch.arising.linkage
            next_specification.storage_class = branch.arising.storage_class
            next_specification.type_qualifiers = branch.arising.type_qualifiers
            next_specification.type_specifiers = branch.arising.type_specifiers

            branch.finalize_arising

            branch.set_arising(next_specification)

        when FunctionParameter
            branch.finalize_arising
          
        else
          raise "programming error"
        end

      when "."
        if branch.has_pending?
          if branch.pending.last.is_a? TknIdentifier
            raise "TODO"
          else
            raise "error"
          end
        elsif branch.current_scope.is_a? Rocc::Semantic::CompoundStatement # FIXME
          raise "TODO: C99 struct initializer"
        else
          raise "error"
        end

      when "{"
        raise if branch.has_pending?
        
        raise unless branch.current_scope # XXX correct? Or may '{' be used  at "translation unit scope"?

        origin = nil
        
        case branch.current_scope
        when Rocc::Semantic::CeFunction
          origin = branch.current_scope
        else
          raise "todo"
        end

        # XXX differentiate between "blocks" (like function boby, switch block, ...) and "regular" compound statements where braces are not mandatory, but only to group several statements ..?
        cs = Rocc::Semantic::CompoundStatement.new(origin, self)

        if branch.has_arising?
          case branch.arising
          when Rocc::Semantic::Temporary::ArisingSpecification # remember: ArisingDefinition < ArisingSpecification
            case branch.arising.symbol_family
            when CeFunction
              branch.arising.mark_as_definition
              function = branch.finalize_arising
            else
              raise
            end
            
          else
            raise
          end
        end

        branch.enter_scope(function)
        branch.enter_scope(cs)

      when "}"
        raise if branch.has_pending?
        raise if branch.has_arising?
        raise "invalid current scope -- #{branch.scope_stack_trace}" unless branch.current_scope.is_a? Rocc::Semantic::CompoundStatement
        branch.current_scope.close(self)
        branch.leave_scope
        branch.leave_scope if branch.current_scope.is_a? Rocc::Semantic::CeFunction

      when "("
        if branch.has_pending?

          if branch.pending_tokens.last.text == "sizeof"
            raise "not yet supported"
          end
          
          super

          #ArisingParentheses.new(self)
          
          #case branch.pending_tokens.last
          #when TknIdentifier
          #else
          #  raise
          #end
          
        else # no pending
          
          if branch.has_arising?
            case branch.arising
            when Rocc::Semantic::Temporary::ArisingSpecification
              if (branch.arising.identifier)
                branch.arising.symbol_family = Rocc::Semantic::CeFunction
                function = branch.finalize_arising
                branch.enter_scope(function)
                func_sig = Rocc::Semantic::CeFunctionSignature.new(function, self)
                branch.enter_scope(func_sig)
              else
                raise "not yet supported (#{branch.arising.inspect})"
              end
            else
              raise
            end
          else
            expr = CompoundExpression.new(self)
            branch.enter_scope(expr)
          end
          
        end # has_pending?

      when ")"
        raise if branch.has_pending?
        raise if branch.has_arising?

        case branch.current_scope
        when Rocc::Semantic::CompoundExpression, Rocc::Semantic::CeFunctionSignature
          branch.current_scope.close(self)
          branch.leave_scope
        else
          raise
        end
        
      else
        super
      end # case @text
  
    end # pursue_branch 

#    def expand_with_context(env, ctxt)
#
#      dbg "#{self}.expand_with_context" # at `#{ctxt.inspect}'"
#
#      unbound = ctxt[:unbound_objects]
#      grast = ctxt[:grammar_stack]
#
#      case @text
#
#      when ","
#        case grast.last
#        when GroTranslationUnit, GroCompoundStatement
#          GroDeclaration.wrap_up(env, ctxt)
#        when GroDeclaration
#          grast.last.add_declarator(env, ctxt)
#        when GroEnumeratorList
#          raise "todo"
#        else
#          super
#        end
#
#      when ";"
#        case grast.last
#        when GroTranslationUnit
#          GroDeclaration.wrap_up(env, ctxt)
#          grast.last.finalize(env, ctxt)
#        when GroDeclaration
#          grast.last.add_declarator(env, ctxt)
#          grast.last.finalize(env, ctxt)
#        when GroCompoundStatement
#          # declaration or statement
#          GroStatement.pick!(env, ctxt) # fixme: handle declarations properly
#        when GroControlStructure
#          # statement
#          raise "todo"
#        when GroParenthesized
#          # expression-list in for-loop
#          if grast[-2].is_a? GroControlStructure and grast[-2].origin[0].text == "for" # fixme
#            super # fixme
#          else
#            raise
#          end
#        when GroStructDeclarationList
#          raise "todo"
#        else
#          raise
#          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
#          env.context.delete(ctx)
#          nil
#        end
#
#      when "{"
#        case grast.last
#        when GroTranslationUnit, GroCompoundStatement
#
#          if tagged_declaration_list = GroTaggedDeclarationList.pick!(env, ctxt)
#            grast << tagged_declaration_list
#
#          elsif grast.last.is_a? GroTranslationUnit
#            # function definition
#            function_definition = GroFunctionDefinition.pick!(env, ctxt)
#            raise "assertion" unless function_definition
#            grast << function_definition
#            grast << GroCompoundStatement.new(self, function_definition)
#
#          elsif grast.last.is_a? GroCompoundStatement and unbound.empty?
#            # GroCompoundStatement
#            grast << GroCompoundStatement.new(self, grast.last)
#
#          else
#            raise
#
#          end
#            
#        when GroControlStructure
#          statement = GroCompoundStatement.new(self, grast.last)
#          grast.last.add_statement(statement)
#          grast << statement
#
#        else
#          raise
#          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
#          env.context.delete(ctx)
#          nil
#        end
#
#      when "("
#        grast << GroParenthesized.new(self, grast.last)
#
#      when "["
#        grast << GroBracketed.new(self, grast.last)
#
#      when ")", "}", "]"
#        case grast.last
#        when GroParenthesized, GroBracketed, GroTaggedDeclarationList
#          grast.last.finalize(env, ctxt, self)
#        when GroCompoundStatement
#          grast.last.finalize(env, ctxt, self)
#          case grast.last
#          when GroFunctionDefinition
#            grast.last.finalize(env, ctxt)  
#          when GroCompoundStatement
#            # do nothing
#          else
#            raise
#          end
#
#        else
#          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
#          env.context.delete(ctx)
#          nil
#         
#        end
#
#      else
#        super
#      end
#
#      ctxt
#
#    end # expand_with_context   
    
    def name_dbg
      "Tkn1Pkt[#{@text}]"
    end
    
  end # Tkn1Char

end # module Rocc::CodeElements::CharRepresented::Tokens
