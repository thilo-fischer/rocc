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

# forward declaration (sort of ...)
module Rocc::CodeElements::CharRepresented
  class CeCoPpDirective   < CeCharObject;     end
end

require 'rocc/code_elements/char_represented/preproc_conditionals'
require 'rocc/code_elements/char_represented/preproc_include'
require 'rocc/code_elements/char_represented/preproc_macro'
require 'rocc/code_elements/char_represented/preproc_misc'

module Rocc::CodeElements::CharRepresented

  # FIXME_R handling of comments interfering with pp directives

  class CeCoPpDirective < CeCharObject
    @REGEXP = /#\s*\w+/
    @PICKING_DELEGATEES = [
      CeCoPpInclude,
      CeCoPpConditional,
      CeCoPpDefine,
      CeCoPpUndef,
      CeCoPpError,
      CeCoPpPragma,
      CeCoPpLine
    ]

  end # class CeCoPpDirective

end # module Rocc::CodeElements::CharRepresented::Tokens
