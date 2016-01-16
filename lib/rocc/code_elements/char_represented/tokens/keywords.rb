# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/char_represented/tokens/token'

module Rocc::CodeElements::CharRepresented::Tokens

    # forward declarations
    class CeToken               < Rocc::CodeElements::CodeElement; end
    class TknWord               < Rocc::CodeElements::CharRepresented::Tokens::CeToken; end
    class TknKeyword            < TknWord;        end
    class TknKwCtrlflow         < TknKeyword;     end
    class TknKwTagged           < TknKeyword;     end
    class TknKwTypeSpecifier    < TknKeyword;     end
    class TknKwTypeQualifier    < TknKeyword;     end
    class TknKwStorageClassSpecifier < TknKeyword; end
    class TknKwMisc             < TknKeyword;     end


    class TknKwCtrlflow < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(return if else for while do continue break switch case default goto)

      def pursue_branch(compilation_context)
        ctx = compilation_context #alias
        if ctx.pending?
          ctx.fail(self){"Syntax error: `#{text}' following `#{ctx.pending_to_s}'."}
        else
          super
        end
      end
      
    end


    class TknKwTagged < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(enum struct union)
    end


    class TknKwTypeSpecifier < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(void char short int long float double signed unsigned bool)
    end


    class TknKwTypeQualifier < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(volatile const restrict)
    end


    class TknKwStorageClassSpecifier < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(typedef static extern auto register)

      def pursue_branch(compilation_context)
        ctx = compilation_context # alias
        if another_storclaspec = ctx.pending_tokens.find {|t| t.is_a? TknKwStorageClassSpecifier}
          # XXX is it really a *syntax* error or is it an error at another level?
          ctx.fail(self){"Syntax error: Multipe storage class specifiers given: `#{another_storclaspec.text}' and `#{self.text}'."}
        else
          super
        end
      end

    end


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

    end


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

