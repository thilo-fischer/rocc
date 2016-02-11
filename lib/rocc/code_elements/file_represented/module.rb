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

require 'rocc/code_elements/code_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Represents the element that would be the result from the linker,
  # i.e. a program or library.
  #
  # Named CeModule instead of Module as Module is already occupied
  # from Ruby.
  class CeModule < Rocc::CodeElements::CodeElement

    def initialize(translation_units, name)
      super(translation_units)
      @name = name
    end

    alias translation_units origin
    
    def populate(ctx)
      translation_units.each {|t| t.populate(ctx)}
    end

  end # class CeModule

end # module Rocc::CodeElements::FileRepresented
