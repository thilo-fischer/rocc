# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

require 'rocc/code_elements/code_element'

module Rocc::CodeElements::FileRepresented

  ##
  # Represents the element that would be the result from the linker,
  # i.e. a program or library.
  #
  # Named CeModule instead of Module as Module is already occupied
  # from Ruby.
  class CeModule < CodeElement

    def initialize(translation_units, name)
      super(translation_units)
      @name = name
    end

    alias translation_units origin
    
    def populate
      translation_units.each { |t| t.populate }
    end

  end # class CeModule

end # module Rocc::CodeElements::FileRepresented
