# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects

module Tokens

  class TknWord < CoToken
    # one word-charcter that is no digit
    # followed by an arbitrary number of word-charcters or digits
    @PICKING_REGEXP = /^[A-Za-z_]\w*\b/

    def self.pick!(env)
      if self != TknWord
        # allow subclasses to call superclasses method implementation
        super
      else
        if pick_string(env) then
          tkn = TknKeyword.pick!(env)
          tkn ||= super
        end
      end
    end # pick!
    
    def expand(env)

      if env.preprocessing[:macros].key?(@text) then

        macros = env.preprocessing[:macros][@text]

        if macros.length == 1 && macros.first.conditions.empty?
          CoMacroExpansion.new(self, macros.first).expand(env)
        else
          env_fork_master = env.fork
          macros.each do |m|
            env_fork = env_fork_master.fork
            env_fork_master.preprocessing[:conditional_stack] << CoPpConditions.negate(m.conditions)
            CoMacroExpansion.new(self, m).expand(env_fork)
            env.merge(env_fork)
          end
          if env_fork_master.preprocessing[:conditional_stack].compliable
            super(env_fork_master)
            env.merge(env_fork_master)
          end
        end

      else # no macro
        super(env)
      end

    end # expand

  end # TknWord

  class TknStringLiteral < CoToken
    # a double quote
    # optionally followed by
    # an arbitrary number of arbitrary characters (non-greedy)
    # where the last character is no backslash
    # followed by a double quote
    @PICKING_REGEXP = /^"(.*?[^\\])?"/
  end

  class TknNumber < CoToken
    @PICKING_REGEXP = /^(0[xX])?(\d|\.\d)\d*\a*\b/
  end

  class Tkn3Char < CoToken
    # <<=, >>=, ...
    @PICKING_REGEXP = /^((<<|>>)=|\.\.\.)/
  end

  class Tkn2Char < CoToken
    @PICKING_REGEXP = /^([+\-*\/%=!&|<>\^]=|<<|>>|##)/
  end

  class Tkn1Char < CoToken
    
    @PICKING_REGEXP = /^[+\-*\/%=!&|<>\^,:;?()\[\]{}~#]/

    def expand_with_context(env, ctxt)

      dbg "#{self}.expand_with_context  at `#{ctxt.inspect}'"

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
            function_definition = GroFunctionDefinition.wrap_up(env, ctxt)
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

end # module Tokens
end # module Ooccor::CodeObjects