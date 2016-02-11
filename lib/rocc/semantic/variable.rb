# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'rocc/semantic/typed_symbol'

module Rocc::Semantic

  class CeVariable < CeTypedSymbol

    def self.default_linkage
      :extern
    end

    def name
      "variable `#{@identifier}'"
    end
    
    def name_dbg
      "Var[#{@identifier}]"
    end

    # FIXME? define constant instead of function?
    def self.family
      :variable
    end
    def self.family_character
      'V'
    end
  end # class CeVariable

end # module Rocc::Semantic
