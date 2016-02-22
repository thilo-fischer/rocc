# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

# FIXME_R split to several files

require 'rocc/semantic/arising_specification'
require 'rocc/semantic/statement'
require 'rocc/semantic/expression'
require 'rocc/semantic/function'
require 'rocc/semantic/function_signature'
require 'rocc/semantic/initializer'
require 'rocc/semantic/macro'
require 'rocc/semantic/macro_invocation'

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented
  #class CeCharObject < Rocc::CodeElements::CodeElement; end
  module Tokens; end
  #class Tokens::CeCoToken < CeCharObject; end
  class Tokens::TknWord < Tokens::CeCoToken; end
  class Tokens::TknIdentifier < Tokens::TknWord; end
end

module Rocc::CodeElements::CharRepresented::Tokens

  class TknWord < CeCoToken

    # XXX_F directly pick! on TknWord and not only on TknKeyword, TknIdentifier and override create to create either TknKeyword or TknIdentifier
    
    # one word-charcter that is no digit
    # followed by an arbitrary number of word-charcters or digits
    @REGEXP = /[A-Za-z_]\w*\b/

    ##
    # Order in which to try to delegate picking to other classes is
    # important: test for TknKeyword first and TknIdentifier second as
    # every match for TknKeyword also matches TknIdentifier.
    @PICKING_DELEGATEES = [TknKeyword, TknIdentifier]

    ##
    # Return true if word has been handled and child classes invoking
    # this function don't need to bother about the word anymore, false
    # otherwise. All steps to handle macros are implemented here,
    # handling of keywords and identifiers is implemented in the
    # according subclasses.
    def pursue_branch(compilation_context, branch)
      symbols = branch.find_symbols(:identifier => @text, :symbol_family => [Rocc::Semantic::CeMacro]) #, Rocc::Semantic::CeTypedef])
      macro_without_additional_conditions = 0 # XXX(ut) defensive programming. remove when according (unit) tests are in place
      symbols.each do |sym|
        case sym
        when Rocc::Semantic::CeMacro
          if branch.conditions.imply?(sym.existence_conditions)
            # XXX(ut)>
            macro_without_additional_conditions += 1
            raise if macro_without_additional_conditions > 1
            # <XXX(ut)
            macro_branch = branch
          else
            macro_branch = branch.fork(sym.existence_conditions.complement(branch.conditions), sym)
          end
          #warn "XXXX #{macro_branch}"
          m_invoc = Rocc::Semantic::CeMacroInvokation.new(self, sym)
          m_invoc.pursue_branch(compilation_context, macro_branch)
        #when Rocc::Semantic::CeTypedef
        #  raise "not yet supported"
        else
          raise "programming error"
        end
      end
      return macro_without_additional_conditions != 0 # TODO_R is it that simple? should require additional branching also if macros with additinal conditions were found.
    end # pursue_branch

    FAMILY_ABBREV = 'TknWord'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
  end # class TknWord

  class TknIdentifier < TknWord
    @REGEXP = /[A-Za-z_]\w*\b/
    
    def pursue_branch(compilation_context, branch)
      # handle word if it is identifier of a macro
      return if super

      raise if branch.has_pending? # FIXME? handle pending '*' and '&' tokens here ?!?

      case branch.current_scope
      when Rocc::Semantic::Temporary::ArisingSpecification
        # TODO set arising_spec TYPE (instead of identifier) if identifier is name of a typedef
        branch.current_scope.set_identifier(self)
      when Rocc::Semantic::CeRValue
        branch.current_scope.expression = Rocc::Semantic::AtomicExpression.new(branch.current_scope, self)
      # FIXME set to ArisingExpression that collects expressions and operators to form a Atomic- or CompoundExpression at finalization
      when Rocc::Semantic::Expression
        raise unless r_val_scope = branch.find_scope(Rocc::Semantic::CeRValue)
        # FIXME? r_val_scope.expression = 
      else
        raise unless branch.current_scope == branch.closest_symbol_origin_scope # FIXME laborious test if current scope can be symbol origin
        arising = Rocc::Semantic::Temporary::ArisingSpecification.new(branch.closest_symbol_origin_scope, branch.conditions)
        branch.enter_scope(arising)
        # TODO set arising_spec TYPE (instead of identifier) if identifier is name of a typedef
        branch.current_scope.set_identifier(self)
      end
    end
    
    FAMILY_ABBREV = 'TknId'
    def self.family_abbrev
      FAMILY_ABBREV
    end

 end # class TknIdentifier

  class TknLiteral < CeCoToken
    def pursue_branch(compilation_context, branch)
      if branch.has_pending?
        super
      else
        case branch.current_scope
        when Rocc::Semantic::ExpressionMixin, Rocc::Semantic::CeRValue # TODO? make Rocc::Semantic::CeRValue take over from Rocc::Semantic::ExpressionMixin
          branch.current_scope.expression = Rocc::Semantic::AtomicExpression.new(branch.current_scope, self)
        # FIXME set to ArisingExpression that collects expressions and operators to form a Atomic- or CompoundExpression at finalization
        end
      end
    end # pursue_branch
  end # class TknLiteral
  
  class TknIntegerLiteral < TknLiteral
    @REGEXP = Regexp.union(/[+-]?\d+[ul]*\b/i, /^[+-]?0x(\d|[abcdef])+[ul]*\b/i)
    
    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    FAMILY_ABBREV = 'TknInt'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
  end # class TknIntegerLiteral

  class TknFloatLiteral < TknLiteral
    # C99 allows hex float literals
    # XXX_R allow hex float litarals only when in C99 compability mode
    @REGEXP = Regexp.union(/[+-]?(\d+\.|\.\d)\d*(e[+-]?\d+)?\b/i, /^[+-]?((\d|[abcdef])+\.|\.(\d|[abcdef]))(\d|[abcdef])*p[+-]?\d+\b/i)

    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    FAMILY_ABBREV = 'TknFloat'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
  end # class TknFloatLiteral

  class TknCharLiteral < TknLiteral
    @REGEXP = Regexp.union(/L?'.'/, /^L?'\\(['"?\\abfnrtv]|[01234567]+|[xuU](\d|[AaBbCcDdEeFf])+)'/)
    
    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    FAMILY_ABBREV = 'TknChar'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
  end # class TknCharLiteral

  class TknStringLiteral < TknLiteral
    # an optional 'L' followed by
    # a double quote
    # optionally followed by
    # an arbitrary number of arbitrary characters (non-greedy)
    # where the last character is no backslash
    # followed by a double quote
    @REGEXP = /L?"(.*?[^\\])?"/

    def pursue_branch(compilation_context, branch)
      super
      #branch.announce_symbol(self)
    end # pursue_branch
    
    FAMILY_ABBREV = 'TknStr'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
  end # class TknStringLiteral

  # XXX rename: TknNChar => TknNPunktuationChar
  class Tkn3Char < CeCoToken
    # <<=, >>=, ...
    @REGEXP = Regexp.union('<<=', '>>=', '...')
    FAMILY_ABBREV = 'Tkn3Pkt'
    def self.family_abbrev
      FAMILY_ABBREV
    end
  end

  class Tkn2Char < CeCoToken
    @REGEXP = Regexp.union(/[+\-*\/%&|\^]=/, /[=!<>]=/, '<<', '>>', '##')
    FAMILY_ABBREV = 'Tkn2Pkt'
    def self.family_abbrev
      FAMILY_ABBREV
    end
  end

  class Tkn1Char < CeCoToken
    
    @REGEXP = /[+\-*\/%=!&|<>\^,:;?()\[\]{}~#]/

    def pursue_branch(compilation_context, branch)
      # FIXME refactor: split into smaller functions

      case @text
         
      when ';'
        raise "still pending: `#{branch.pending_to_s}'" if branch.has_pending?

        ## XXX? smells (?): two successive `case branch.current_scope'
        #case branch.current_scope
        #when Rocc::Semantic::CeRValue #, Rocc::Semantic::CeFunction
        #  if branch.current_scope.complete?
        #    branch.leave_scope
        #  else
        #    raise "found #{name_dbg}, but #{branch.current_scope.name_dbg} is not complete"
        #  end
        #end
        
        case branch.current_scope

        when Rocc::Semantic::CompoundStatement, Rocc::CodeElements::FileRepresented::CeTranslationUnit
          # XXX warn about superflous ';' token

        when Rocc::Semantic::Temporary::ArisingSpecification,
             Rocc::Semantic::CeInitializer
          branch.finish_current_scope
          branch.leave_scope
          
        when Rocc::Semantic::Statement          
          if branch.current_scope.complete?
            branch.leave_scope
          else
            raise "found #{name_dbg}, but #{branch.current_scope.name_dbg} is not yet complete"
          end

        else
          raise unless branch.current_scope.complete? # XXX(assert)
          branch.leave_scope
          # recurse down the scope
          pursue_branch(compilation_context, branch)
          
        end
        
      when ','
        
        case branch.surrounding_scope
            
        when Rocc::Semantic::Temporary::CeFunctionSignature
          raise unless branch.current_scope.is_a?(Rocc::Semantic::Temporary::ArisingSpecification) # XXX(assert)
          wrapup_function_parameter(branch.surrounding_scope, branch.current_scope)
          branch.leave_scope
          
        else

          case branch.current_scope
          when Rocc::Semantic::CeInitializer,
               Rocc::Semantic::Temporary::ArisingSpecification
            branch.finish_current_scope
            prev_arising = branch.leave_scope
            
            next_arising = Rocc::Semantic::Temporary::ArisingSpecification.new(branch.closest_symbol_origin_scope, branch.conditions)
            next_arising.share_origin(prev_arising)
            branch.enter_scope(next_arising)
          else
            raise "unexpected #{self} at #{location}"
          end

        end

      when '.'
        if branch.has_pending?
          if branch.pending.last.is_a? TknIdentifier
            branch.push_pending(self)
            raise "TODO"
          else
            raise "error"
          end
        elsif branch.current_scope.is_a? Rocc::Semantic::CompoundStatement # FIXME
          raise "TODO: C99 struct initializer"
        else
          raise "error"
        end

      when '{'
        raise if branch.has_pending?
        raise unless branch.current_scope # XXX correct? Or may '{' be used  at "translation unit scope"?

        case branch.current_scope
        when Rocc::Semantic::Temporary::ArisingSpecification
          if branch.current_scope.is_function?
            branch.current_scope.mark_as_definition
            func_decl = branch.finish_current_scope # XXX rename method CompilationBranch#finish_current_scope
            func_def  = Rocc::Semantic::CeFunctionDefinition.new(func_decl)
            branch.enter_scope(func_def)
            # XXX? differentiate between "blocks" (like function boby, switch block, ...) and "regular" compound statements where braces are not mandatory, but only to group several statements ?
            func_body = Rocc::Semantic::CompoundStatement.new(func_def, self)
            branch.enter_scope(func_body)
          else
            raise "programming error or not yet supported"
          end
        when Rocc::Semantic::CompoundStatement
          raise "not yet supported"
        when Rocc::Semantic::SubstatementMixin
          raise "not yet supported"
        else
          raise "programming error: unexpected scope at #{path_dbg} -- #{branch.scope_stack_trace}"
        end

      when '}'
        raise if branch.has_pending?

        case branch.current_scope
        when Rocc::Semantic::CompoundStatement
          branch.current_scope.close(self)
          branch.finish_current_scope
          branch.leave_scope
        else
          raise "programming error or not yet supported: invalid current scope -- #{branch.scope_stack_trace}"
        end

      when '('
        if branch.has_pending?

          if branch.pending_tokens.last.text == "sizeof"
            raise "not yet supported"
          end
          
          super

        else # no pending
          
          case branch.current_scope
          when nil
            raise "not yet supported"
            
          when Rocc::Semantic::Temporary::ArisingSpecification
            a = branch.current_scope
            if a.identifier
              a.mark_as_function
              func_sig = Rocc::Semantic::Temporary::CeFunctionSignature.new(self)
              a.parameters=(func_sig)
              branch.enter_scope(func_sig)
            else
              raise "not yet supported (#{a.inspect})"
            end
          when Rocc::Semantic::CeRValue
            expr = Rocc::Semantic::CompoundExpression.new(branch.current_scope, self)
            branch.current_scope.expression = expr
            branch.enter_scope(expr)
          when Rocc::Semantic::IfStatement, Rocc::Semantic::WhileStatement, Rocc::Semantic::DoWhileStatement
            raise "TODO"
          when Rocc::Semantic::ForStatement
            raise "TODO"
          when Rocc::Semantic::SwitchStatement
            raise "TODO"
          #when Rocc::Semantic::SizeofExpression
          #  raise "TODO"
          else
            raise "not yet supported"
          end
          
        end # has_pending?

      when ')'
        raise "found #{name_dbg}, but still pending: `#{branch.pending_to_s}'" if branch.has_pending?

        case branch.current_scope
        when Rocc::Semantic::Temporary::ArisingSpecification
          case branch.surrounding_scope
          when Rocc::Semantic::Temporary::CeFunctionSignature
            wrapup_function_parameter(branch.surrounding_scope, branch.current_scope)
            branch.leave_scope
          else
            raise
          end
        when Rocc::Semantic::CompoundExpression, Rocc::Semantic::Temporary::CeFunctionSignature
          # do nothing, handle in next case statement
        else
          raise "found #{name_dbg}, but #{branch.scope_stack_trace}"
        end

        case branch.current_scope
        when Rocc::Semantic::CompoundExpression, Rocc::Semantic::Temporary::CeFunctionSignature
          branch.current_scope.close(self)
          branch.leave_scope
        else
          raise "found #{name_dbg}, but #{branch.scope_stack_trace}"
        end
        
      when '*'
        case branch.current_scope
        when Rocc::Semantic::Temporary::ArisingSpecification
            # FIXME handle asterisk (->pointer) => branch.current_scope. ...
        when Rocc::Semantic::CeRValue
            # FIXME handle asterisk (->object from pointer)
        else
          raise "not yet supported: #{name_dbg} outside of specification"
        end
        
      when '&'
        case branch.current_scope
        when Rocc::Semantic::CeRValue, Rocc::Semantic::Expression
            # FIXME handle ampersand (->pointer)
        else
          raise "not yet supported: #{name_dbg} outside of specification"
        end
        
      when '='
        case branch.current_scope
        when Rocc::Semantic::Temporary::ArisingSpecification
          branch.current_scope.mark_as_variable
          branch.current_scope.mark_as_definition
          var_decl = branch.finish_current_scope # XXX rename method CompilationBranch#finish_current_scope
          var_def  = Rocc::Semantic::CeVariableDefinition.new(var_decl)
          branch.enter_scope(var_def)
          var_init = Rocc::Semantic::CeInitializer.new(var_def)
          branch.enter_scope(var_init)
        when Rocc::Semantic::CompoundStatement
          if branch.current_scope.has_pending?
            raise "not an r-value (or no support implemented yet for this kind of rvalue): `#{branch.current_scope.pending_to_s}'" unless branch.pending_tokens.count == 1 and branch.pending.first.is_a?(Rocc::CodeElements::CharReperesented::TknIdentifier)
            raise "TODO setup arising assignment statement"
          else
            raise "invalid syntax at #{path}"
          end
        else
          raise "not yet supported: #{name_dbg} outside of specification"
        end
        
      else
        super
      end # case @text
  
    end # pursue_branch 

    
    def wrapup_function_parameter(function_signature, arising_param)
      if arising_param.identifier
        function_signature.add_param(arising_param.origin, arising_param.type_specifiers, arising_param.identifier, arising_param.storage_class)
      elsif arising_param.type_specifiers == [:void] and arising_param.storage_class == nil
        function_signature.mark_as_void(arising_param.origin)
      else
        raise "not yet supported"
      end
    end
    private :wrapup_function_parameter
    

    FAMILY_ABBREV = 'Tkn1Pkt'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
  end # Tkn1Char

end # module Rocc::CodeElements::CharRepresented::Tokens
