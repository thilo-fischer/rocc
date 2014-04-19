# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects::Tokens

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

      if env.preprocessing[:macros].key?(@name) then

        macros = env.preprocessing[:macros][@name]

        if macros.length == 1 && macros.first.conditions.empty?
          env.parsing[:macro_expansion_stack] << macros.first
          macros.first.tokens.expand(env)
        else
          env_fork_master = env.fork
          macros.each do |m|
            env_fork = env_fork_master.fork
            env_fork.parsing[:macro_expansion_stack] << m
            # todo: optimize by collapsing overlapping conditions and skipping excluding conditions
            env_fork.preprocessing[:conditional_stack] << m.conditions
            env_fork_master.preprocessing[:conditional_stack] << m.conditions.negate
            m.tokens.expand(env_fork)
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

      free = ctxt[:unassociated_tokens]
      scope = ctxt[:scope_stack]

      case @text

      when ","
        if scope.empty? or [ CoCompoundStatement ].includes? scope.last.class
          free << CoDeclaratorListItem.new(env)
        else
          separators[","] = [ free.last ]
        end

      when ";"
        if free.length == 0
          TRUE
          
        elsif separators.key?(",")

          scope.empty?

          ...
          
        elsif [ CoCompoundStatement, CoControlStructure ].includes? scope.last.class
          ...

        elsif free.length >= 2 and free[-2].is_a? ... and free[-1].is_a? CoParentheses

        else
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          env.context.delete(ctx)
          nil
         
        end

      when "{"
        if FALSE # to align all the elsif conditions ...
          
        elsif free.length >= 1 and free[-1].is_a? TknKwTagged
          scope << free[-1].define(env, self)

        elsif free.length >= 2 and free[-2].is_a? TknKwTagged and free[-1].is_a? TknWord
          scope << free[-2].define(env, self, free[-1])

        elsif free.length >= 2 and free[-2].is_a? TknWord and free[-1].is_a? CoParentheses then
          scope << CoFunctionDefinition.new(env, free)

        elsif [ CoFunctionDefinition, CoControlStructure, CoCompoundStatement ].includes? scope.last.class
          scope << CoCompoundStatement.new(env, self)

        else
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          env.context.delete(ctx)
          nil
         
        end

      when "("
        scope << CoParentheses.new(env, self)

      when "["
        scope << CoBrackets.new(env, self)

      when ")", "}", "]"
        if [ CoParentheses, CoCompoundStatement, CoBrackets ].includes? scope.last.class or scope.last.is_a? CoTaggedDefinition
          scope.last.close(env, self)

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

end # module Ooccor::CodeObjects::Tokens
