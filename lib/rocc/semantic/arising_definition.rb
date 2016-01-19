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

module Rocc::Semantic::Temporary

  class ArisingDefinition < ArisingSpecification

    def initialize(specification)
      origin = specification.origin
      symbol_family = specification.symbol_family
      identifier = specification.identifier
      linkage = specification.linkage
      storage_class = specification.storage_class
      type_qualifiers = specification.type_qualifiers
      type_specifiers = specification.type_specifiers
    end

    private
    def finish_class
      CeDefinition
    end


  end # class ArisingDefinition

end # module Rocc::Semantic
