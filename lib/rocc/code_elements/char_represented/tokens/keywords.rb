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
require 'rocc/semantic/function'
require 'rocc/semantic/r_value'

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented
  module Tokens; end
  #class Tokens::CeCoToken < CeCharObject; end
  #class Tokens::TknWord < Tokens::CeCoToken; end
  class Tokens::TknKeyword < Tokens::TknWord; end
end

module Rocc::CodeElements::CharRepresented::Tokens

    class TknKwCtrlflow < TknKeyword
      @REGEXP = Regexp.union %w(return if else for while do continue break switch case default goto)

      def pursue_branch(compilation_context, branch)
        # handle word if it is identifier of a macro
        return if super

        if branch.has_pending?
          # FIXME exception
          branch.fail{"Syntax error: #{name_dbg} `#{text}' following `#{branch.pending_to_s}'."}
        else

          keyword = @text.to_sym

          case keyword
              
          when :return
            function = branch.find_scope(Rocc::Semantic::CeFunction)
            raise "`#{keyword}' used outside of function" unless function
            s = Rocc::Semantic::ReturnStatement.new(branch.current_scope, self, function)
            branch.enter_scope(s)
            rv = Rocc::Semantic::CeRValue.new(s)
            branch.enter_scope(rv)
            s.expression = rv
            
          when :else
            bmrs = branch.most_recent_scope
            raise "programming error" unless bmrs.is_a?(Rocc::Semantic::IfStatement)
            s = Rocc::Semantic::ElseStatement.new(branch.current_scope, self, bmrs)
            branch.enter_scope(s)
            
          when :while
            if branch.current_scope.is_a?(Rocc::Semantic::DoWhileStatement)
              raise "not yet supported"
            else
              raise "not yet supported -> same as case's else branch"               
            end
            
          when :continue
            affected_scope = branch.find_scope(Rocc::Semantic::IterationStatement)
            raise "`#{keyword}' used outside of loop" unless affected_scope
            s = Rocc::Semantic::ContinueStatement.new(branch.current_scope, self, affected_scope)
            branch.enter_scope(s)
            
          when :break
            affected_scope = branch.find_scope(Rocc::Semantic::IterationStatement, Rocc::Semantic::SwitchStatement)
            raise "`#{keyword}' used outside of loop and switch" unless affected_scope
            s = Rocc::Semantic::BreakStatement.new(branch.current_scope, self, affected_scope)
            branch.enter_scope(s)
            
          else
            statement_class = KEYWORD_TO_ORDINARY_STATEMENT_MAP[keyword]
            raise "programming error" unless statement_class
            s = statement_class.new(branch.current_scope, self)
            branch.enter_scope(s)
            
          end # case keyword
          
        end # 
      end # pursue_branch
      
    end # class TknKwCtrlflow


    class TknKwTagged < TknKeyword 
      @REGEXP = Regexp.union %w(enum struct union)
      
      def pursue_branch(compilation_context, branch)
        # handle word if it is identifier of a macro
        return if super

        invalid_ptkn = branch.pending_tokens.find do |ptkn|
          case ptkn
          when TknKwTypeQualifier, TknKwStorageClassSpecifier
            false
          else
            true
          end
        end
        if invalid_ptkn
          branch.fail{"Syntax error: #{name_dbg} `#{text}' following #{invalid_ptkn.name_dbg} `#{invalid_ptkn.text}' (`#{branch.pending_to_s}#{text}')."}
        else
          # FIXME handle pending tokens
          arisig = ArisingSpecification.new(self)
          arising.symbol_family = case @text
                                  when "enum"
                                    CeEnum
                                  when "struct"
                                    CeStruct
                                  when "union"
                                    CeUnion
                                  else
                                    raise "programming error"
                                  end
          branch.enter_scope(arising)
        end
      end # pursue_branch
      
    end # class TknKwTagged


    class TknKwTypeSpecifier < TknKeyword
      @REGEXP = Regexp.union %w(void char short int long float double signed unsigned bool) # XXX C99 featrue bool required #include <stdbool.h>

      def pursue_branch(compilation_context, branch)
        # handle word if it is identifier of a macro
        return if super

        raise "unexpected pending tokens: `#{branch.pending_to_s}'" if branch.has_pending?
        unless branch.current_scope.is_a? Rocc::Semantic::Temporary::ArisingSpecification
          arising = Rocc::Semantic::Temporary::ArisingSpecification.new
          branch.enter_scope(arising)
        end
        branch.current_scope.add_type_specifier(self)
      end # pursue_branch
      
      def name_dbg
        "TknType[#{@text}]"
      end

      def type_specifier_symbol
        @text.to_sym
      end
    
    end # class TknKwTypeSpecifier


    class TknKwTypeQualifier < TknKeyword
      @REGEXP = Regexp.union %w(volatile const restrict)
      
      def pursue_branch(compilation_context, branch)
        # handle word if it is identifier of a macro
        return if super

        raise if branch.has_pending?
        unless branch.current_scope.is_a? Rocc::Semantic::Temporary::ArisingSpecification
          arising = Rocc::Semantic::Temporary::ArisingSpecification.new
          branch.enter_scope(arising)
        end
        branch.current_scope.add_type_qualifier(self)
      end # pursue_branch
      
      def name_dbg
        "TknTQual[#{@text}]"
      end

      def type_qualifier_symbol
        @text.to_sym
      end
   end


    class TknKwStorageClassSpecifier < TknKeyword
      @REGEXP = Regexp.union %w(typedef static extern auto register)

      def pursue_branch(compilation_context, branch)
        # handle word if it is identifier of a macro
        return if super

        raise if branch.has_pending?
        
        # TODO typedef needs special treatment

        unless branch.current_scope.is_a? Rocc::Semantic::Temporary::ArisingSpecification
          arising = Rocc::Semantic::Temporary::ArisingSpecification.new
          branch.enter_scope(arising)
        end
        branch.current_scope.set_storage_class(self)
        
        # alias for shorter code lines
        storage_class = branch.current_scope.storage_class

        if branch.find_scope(Rocc::Semantic::CeFunction)
          if branch.find_scope(Rocc::Semantic::CeFunctionSignature)
            raise "register is the only storage class specifier allowed for function parameters" unless storage_class == :register
          else
            # XXX all storage class specifiers allowed in function body? (=> typedef?)
            #raise if [].include?(storage_class)
          end
        else
          raise "auto not allowed outside of function body" if [:auto].include?(storage_class)
        end
      end

      def storage_class_specifier_symbol
        @text.to_sym
      end
       
   end # class TknKwStorageClassSpecifier


    class TknKwSpecifier < TknKeyword

      @PICKING_DELEGATEES = [ TknKwTypeSpecifier, TknKwStorageClassSpecifier ]

    end # class TknKwSpecifier


    class TknKwMisc < TknKeyword
      @REGEXP = Regexp.union %w(inline sizeof _Complex _Imaginary)
    end


    class TknKeyword < TknWord

      @PICKING_DELEGATEES = [ TknKwCtrlflow, TknKwTagged, TknKwTypeSpecifier, TknKwTypeQualifier, TknKwStorageClassSpecifier, TknKwMisc ]

    end # TknKeyword

end # module Rocc::CodeElements::CharRepresented::Tokens

