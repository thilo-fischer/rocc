# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisly the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

module Rocc; end

module Rocc::Helpers

  def self.backtrace(depth = -1, skip = 1)
    stack = caller(skip)[0..(depth>0?depth-1:depth)]
    stack.inject("Backtrace:\n") {|result, element| result + "\t#{element}\n" }
  end # def backtrace
  
end # module Rocc::Helpers
