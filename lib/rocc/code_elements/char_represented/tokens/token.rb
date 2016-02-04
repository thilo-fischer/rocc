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

require 'rocc/code_elements/tokens/keywords'
require 'rocc/code_elements/tokens/misc_tokens'

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented
  class CeCharObject < Rocc::CodeElements::CodeElement; end
  module Tokens
    class Rocc::CodeElements::CharRepresented::Tokens::CeCoToken; end
  end
end

module Rocc::CodeElements::CharRepresented::Tokens

  # forward declarations
  class CeCoToken          < Rocc::CodeElements::CharRepresented::CeCharObject; end
  class TknWord           < CeCoToken; end
  class TknLiteral        < CeCoToken; end
  class TknIntegerLiteral < TknLiteral; end
  class TknFloatLiteral   < TknLiteral; end
  class TknCharLiteral    < TknLiteral; end
  class TknStringLiteral  < TknLiteral; end
  class Tkn3Char          < CeCoToken; end
  class Tkn2Char          < CeCoToken; end
  class Tkn1Char          < CeCoToken; end

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
