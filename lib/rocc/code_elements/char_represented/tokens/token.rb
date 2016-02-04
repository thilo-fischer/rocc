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
    
  end # CeCoToken

end # module Rocc::CodeElements::CharRepresented::Tokens
