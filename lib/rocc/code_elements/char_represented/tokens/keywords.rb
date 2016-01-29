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

require 'rocc/code_elements/char_represented/tokens/token'

require 'rocc/semantic/arising_specification'
require 'rocc/semantic/statement'
#require 'rocc/semantic/expression' # not (yet) in use
require 'rocc/semantic/function'
require 'rocc/semantic/r_value'

module Rocc::CodeElements::CharRepresented::Tokens

    # forward declarations
    class CeToken               < Rocc::CodeElements::CodeElement; end
    class TknWord               < CeToken; end
    class TknKeyword            < TknWord;        end
    class TknKwCtrlflow         < TknKeyword;     end
    class TknKwTagged           < TknKeyword;     end
    class TknKwTypeSpecifier    < TknKeyword;     end
    class TknKwTypeQualifier    < TknKeyword;     end
    class TknKwStorageClassSpecifier < TknKeyword; end
    class TknKwMisc             < TknKeyword;     end


    class TknKwCtrlflow < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(return if else for while do continue break switch case default goto)

      def pursue_branch(compilation_context, branch)
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
      @PICKING_REGEXP = Regexp.union %w(enum struct union)
      
      def pursue_branch(compilation_context, branch)
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
      @PICKING_REGEXP = Regexp.union %w(void char short int long float double signed unsigned bool) # XXX C99 featrue bool required #include <stdbool.h>

      def pursue_branch(compilation_context, branch)
        raise "unexpected pending tokens: `#{branch.pending_to_s}'" if branch.has_pending?
        unless branch.current_scope.is_a? Rocc::Semantic::Temporary::ArisingSpecification
          arising = Rocc::Semantic::Temporary::ArisingSpecification.new
          branch.enter_scope(arising)
        end
        warn "#{name_dbg} #{branch.scope_stack_trace}"
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
      @PICKING_REGEXP = Regexp.union %w(volatile const restrict)
      
      def pursue_branch(compilation_context, branch)
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
      @PICKING_REGEXP = Regexp.union %w(typedef static extern auto register)

      def pursue_branch(compilation_context, branch)
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

      THIS_CLASS = TknKwSpecifier
      SUBCLASSES = [ TknKwTypeSpecifier, TknKwStorageClassSpecifier ] # fixme(?): use `inherited' hook ?
      @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

      # TODO old implementation. still in accordance with pick/pick_string/pick_string!/create ?
      def self.pick!(env)
        if self != THIS_CLASS
          # allow subclasses to call superclass' method implementation
          super
        else
          tkn = nil
          SUBCLASSES.find {|c| tkn = c.pick!(env)}
          tkn
        end
      end   

    end # class TknKwSpecifier


    class TknKwMisc < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(inline sizeof _Complex _Imaginary)
    end


    class TknKeyword < TknWord

      THIS_CLASS = TknKeyword
      SUBCLASSES = [ TknKwCtrlflow, TknKwTagged, TknKwTypeSpecifier, TknKwTypeQualifier, TknKwStorageClassSpecifier, TknKwMisc ]
      @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

      # XXX test which version of pick! works faster, this or the one commented out below. (adapt TknKwSpecifier.pick! accordingly)

      def self.pick_string!(tokenization_context)
        str = tokenization_context.remainder.slice!(Regexp.new("^(#{@PICKING_REGEXP.source})")) # FIXME quick and dirty => rebuilding regexp at every pick_string! is a performance issue!
      end

      def self.pick!(env)
        if self != THIS_CLASS
          # allow subclasses to call superclass' method implementation
          super
        else
          tkn = nil
          SUBCLASSES.find {|c| tkn = c.pick!(env)}
          tkn
        end
      end   

      #  def self.pick!(env)
      #    if str = self.pick_string(env) then
      #      tkn = nil
      #      if SUBCLASSES.find {|c| tkn = c.pick!(env)} then
      #        tkn
      #      else
      #        raise StandardError, "Error processing keyword, not accepted by subclasses @#{origin.list}: `#{str}'"
      #      end
      #    end
      #  end   

    end # TknKeyword

end # module Rocc::CodeElements::CharRepresented::Tokens

