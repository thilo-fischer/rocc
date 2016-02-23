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

module Rocc::Semantic

  class CeRValue < Rocc::CodeElements::CodeElement

    ##
    # +origin+ is the statement or definition this r-value is part of
    def initialize(origin)
      super(origin)
      @expression = nil
    end

    def adducer
      @expression.adducer if @expression
    end
    
    def complete?
      @expression and @expression.complete?
    end

    def expression=(arg)
      raise if @expression
      @expression = arg
    end

    def name_dbg
      "<r-value>"
    end

    def finalize
      raise "#{self} incomplete" unless complete?
      self
    end
    
  end # class CeRValue

end # module Rocc::Semantic
