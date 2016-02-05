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

require 'rocc/helpers'
require 'rocc/code_elements/code_element'

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented::Tokens
  class CeCoToken < Rocc::CodeElements::CharRepresented::CeCharObject; end
  class TknWord < CeCoToken; end
end

require 'rocc/code_elements/char_represented/tokens/keywords'
require 'rocc/code_elements/char_represented/tokens/misc_tokens'

module Rocc::CodeElements::CharRepresented::Tokens

  # XXX_R abstract class => forbid initialization
  class CeCoToken < Rocc::CodeElements::CharRepresented::CeCharObject

    ##
    # Order in which to try to delegate picking to other classes is
    # important: test for Tkn3Char before Tkn2Char and for Tkn2Char
    # before Tkn1Char to ensure to detect e.g. the >>= token not as as
    # tokens > and >= or as tokens >, > and =.
    @PICKING_DELEGATEES = [
      TknWord,
      TknStringLiteral,
      TknCharLiteral,
      TknIntegerLiteral,
      TknFloatLiteral,
      TknCharLiteral,
      TknStringLiteral,
      Tkn3Char,
      Tkn2Char,
      Tkn1Char
    ]

    #def initialize(origin, text, charpos, whitespace_after = nil, direct_predecessor = nil)
    #  super
    #end # initialize

    FAMILY_ABBREV = 'Tkn'
    def self.family_abbrev
      FAMILY_ABBREV
    end
    
    ##
    # CeCoToken's implementation of CodeElement#pursue.
    def pursue(compilation_context)
      raise "Child classes of CeCoToken shall not override pursue, override pursue_branch instead." unless self.class == CeCoToken # XXX(ut)

      super_duty = super
      return nil if super_duty.nil?
      
      if compilation_context.has_token_request?
        log.debug{"#{compilation_context.token_requester.name_dbg}.process_token\nToken: #{path_dbg}"} # TODO loglevel trace ?! log with specific log tag?
        compilation_context.token_requester.process_token(compilation_context, self)
        # Achieved all operations necessary to pursue the
        # context. Chaining child class' method implementation does
        # not need to take any further steps. Thus, return nil.
        return nil
      end

      active_branches = compilation_context.active_branches
      raise "no active branches" if active_branches.empty? # XXX(ut)

      # pursue all active branches
      active_branches.each do |b|
        if b.has_token_request?
          log.debug{"#{b.token_requester.name_dbg}.process_token\nToken: #{path_dbg}"} # TODO loglevel trace ?! log with specific log tag?
          b.token_requester.process_token(compilation_context, b, self)
        else
          log.debug{"#{name_dbg}.pursue_branch #{b.id}\nToken: #{path_dbg}\n#{b.scope_stack_trace}"} # TODO loglevel trace ?! log with specific log tag?
          pursue_branch(compilation_context, b)
        end
      end

      # join as many branches as possible
      active_branches.each {|b| b.try_join}

      log.debug{ "active branches: #{active_branches.map {|b| b.name_dbg}.join(', ')}" }
      
      # adapt set of active branches according to the branch
      # activations and deactivations that may have happened from this
      # token
      compilation_context.sync_branch_activity
    end

    ##
    # Process this token within the given compilation context.
    # Default implementation suitable for all tokens that can't do
    # anything better: Add token to the list of pending tokens.
    # Concrete token classes shall override this method when possible.
    def pursue_branch(compilation_context, branch)
      branch.push_pending(self)
    end

  end # CeCoToken

end # module Rocc::CodeElements::CharRepresented::Tokens
