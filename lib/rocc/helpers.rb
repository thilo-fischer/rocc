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

module Rocc; end

module Rocc::Helpers

  def self.backtrace(depth = -1, skip = 1)
    stack = caller(skip)[0..(depth>0?depth-1:depth)]
    stack.inject("Backtrace:\n") {|result, element| result + "\t#{element}\n" }
  end # def backtrace

  module String
  
  ##
  # replace all line breaks in string with unicode character "symbol
  # for newline"
  def self.no_lbreak(str)
    str.gsub("\n", "\u2424")
  end

  ##
  # If +str+ is less than +length+ long, return string. Return an
  # abbreviated +str+ representation otherwise: the first +length - 1+
  # plus unicode character `horizontal ellipsis' otherwise.
  def self.abbrev(str, length = 12)
    if str.length > length
      str[0..(length-2)] + "\u2026"
    else
      str
    end
  end

  end # module String
end # module Rocc::Helpers
