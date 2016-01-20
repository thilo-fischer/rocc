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
          branch.fail{"Syntax error: #{name_dbg} `#{text}' following `#{branch.pending_to_s}'."}
        else

          keyword = @text.to_sym

          case keyword
              
          when :return
            function = branch.find_scope(Rocc::Semantic::CeFunction)
            raise "`#{keyword}' used outside of function" unless function
            s = Rocc::Semantic::ReturnStatement.new(branch.current_scope, self, function)
            branch.enter_scope(s)
            
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
          arisig = case @text
                   when "enum"
                     CeEnum
                   when "struct"
                     CeStruct
                   when "union"
                     CeUnion
                   else
                     raise "programming error"
                   end
          branch.arising = arising
          super
        end
      end # pursue_branch
      
    end # class TknKwTagged


    class TknKwTypeSpecifier < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(void char short int long float double signed unsigned bool)

      def pursue_branch(compilation_context, branch)
        invalid_ptkn = branch.pending_tokens.find do |ptkn|
          case ptkn
          when TknKwTypeQualifier, TknKwStorageClassSpecifier
            false
          when TknKwTypeSpecifier
            (text =~ Regexp.union('char', 'short', 'int', 'long')) and # XXX %w(char short int long)) and
            (ptkn.text == "signed" or ptkn.text == "unsigned")
          else
            true
          end
        end
        if invalid_ptkn
          branch.fail{"Syntax error: #{name_dbg} `#{text}' following #{invalid_ptkn.name_dbg} `#{invalid_ptkn.text}' (`#{branch.pending_to_s}#{text}')."}
        else
          branch.arising = Rocc::Semantic::Temporary::ArisingSpecification.new(branch.pending_tokens)
          super
        end
      end # pursue_branch
      
      def name_dbg
        "TknType[#{@text}]"
      end
    
    end # class TknKwTypeSpecifier


    class TknKwTypeQualifier < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(volatile const restrict)
      def pursue_branch(compilation_context, branch)
        raise "TODO"
      end
   end


    class TknKwStorageClassSpecifier < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(typedef static extern auto register)

      def pursue_branch(compilation_context, branch)

        # TODO typedef needs special treatment

        if branch.has_arising?
          raise unless branch.arising.is_a? Rocc::Semantic::Temporary::ArisingSpecification
        else
          branch.arising = Rocc::Semantic::Temporary::ArisingSpecification.new(self)
        end
        
        branch.arising.storage_class = @text.to_sym

        if branch.find_scope(CeFunction)
          if branch.find_scope(CeFunctionSignature)
            raise "register is the only storage class specifier allowed for function parameters" unless branch.arising.storage_class == :register
          else
            # XXX all storage class specifiers allowed in function body? (=> typedef?)
            #raise if [].includes?(branch.arising.storage_class)
          end
        else
          raise "auto not allowed outside of function body" if [:auto].includes?(branch.arising.storage_class)
        end
        
        case branch.arising.storage_class
        when :extern
          branch.arising.linkage = :extern
        when :static
          branch.arising.linkage = :intern
        end
        
      end

    end # class TknKwStorageClassSpecifier


    class TknKwSpecifier < TknKeyword

      THIS_CLASS = TknKwSpecifier
      SUBCLASSES = [ TknKwTypeSpecifier, TknKwStorageClassSpecifier ] # fixme(?): use `inherited' hook ?
      @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

      # TODO old implementation. still in accordance with pick/pick_string/pick_string!/create ?
      def self.pick!(env)
        if self != THIS_CLASS
          # allow subclasses to call superclasses method implementation
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

      def self.pick!(env)
        if self != THIS_CLASS
          # allow subclasses to call superclasses method implementation
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

