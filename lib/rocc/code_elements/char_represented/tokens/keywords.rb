# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeObjects

  module Tokens

    # forward declarations
    class CoToken               < CodeObject;     end
    class TknWord               < CoToken;        end
    class TknKeyword            < TknWord;        end
    class TknKwCtrlflow         < TknKeyword;     end
    class TknKwTagged           < TknKeyword;     end
    class TknKwTypeSpecifier    < TknKeyword;     end
    class TknKwTypeQualifier    < TknKeyword;     end
    class TknKwStorageClassSpecifier < TknKeyword; end
    class TknKwMisc             < TknKeyword;     end


    class TknKwCtrlflow < TknKeyword
      @PICKING_REGEXP = Regexp.union %w(return if else for while do continue break switch case default goto)

      def expand_with_context(env, ctxt)
        if ctxt[:unbound_objects].empty?
          ctxt[:unbound_objects] << self
        else
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          warn "Found `#{ctxt[:unbound_objects].inspect}' in front of `#{to_s}'"
          env.context_branches.delete(ctxt)
          raise
        end
      end # expand_with_context
      
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

      def expand_with_context(env, ctx)
        if ctx[:unassociated_tokens].find {|t| t.is_a? TknKwStorageClassSpecifier}
          warn "Syntax error with `#{to_s}' when (#{env.preprocessing[:conditional_stack]}). Abort processing of branch with these conditions." # todo: syntax error handling
          env.context.delete(ctx)
          raise
        else
          super
        end
      end # expand_with_context

    end


    class TknKwSpecifier < TknKeyword

      SUBCLASSES = [ TknKwTypeSpecifier, TknKwStorageClassSpecifier ] # fixme(?): use `inherited' hook ?
      @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

      def self.pick!(env)
        if self != TknKwSpecifier
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
      SUBCLASSES = [ TknKwCtrlflow, TknKwTagged, TknKwTypeSpecifier, TknKwTypeQualifier, TknKwStorageClassSpecifier, TknKwMisc ]
      @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

      # todo: test which version of pick! works faster
      # (adapt TknKwSpecifier.pick! accordingly)

      def self.pick!(env)
        if self != TknKeyword
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

  end # module Tokens
end # module Rocc::CodeObjects

