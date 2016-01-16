# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc; end

module Rocc::Helpers

  def self.backtrace(depth = -1, skip = 1)
    stack = caller(skip)[0..(depth>0?depth-1:depth)]
    stack.inject("Backtrace:\n") {|result, element| result + "\t#{element}\n" }
  end # def backtrace
  
end # module Rocc::Helpers
