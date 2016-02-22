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

module Rocc; end

module Rocc::Helpers

  module Debug
    
    module_function

    def dbg_backtrace(depth = -1, skip = 1)
      stack = caller(skip)[0..(depth>0?depth-1:depth)]
      stack.inject("Backtrace:\n") {|result, element| result + "\t#{element}\n" }
    end # def backtrace

  end # module Debug

  module String

    ##
    # replace all line breaks in string with unicode character "symbol
    # for newline"
    def str_no_lbreak(str)
      str.gsub("\n", "\u2424")
    end

    ##
    # If +str+ is less than +length+ long, return string. Return an
    # abbreviated +str+ representation otherwise that is exactly
    # +length+ long: the first +length - 1+ characters plus unicode
    # character `horizontal ellipsis'.
    def str_abbrev(str, length = 12)
      if str.length > length
        raise "invalid argument" unless length > 0
        str[0...(length-1)] + "\u2026"
      else
        str
      end
    end

    ##
    # If +str+ is less than +length+ long, do nothing. Truncate +str+
    # and append unicode character `horizontal ellipsis' such that the
    # resulting string is exactly +length+ characters long otherwise.
    def str_abbrev!(str, length = 12)
      if str.length > length
        str[(length-1)..-1] = "\u2026"
      end
      str
    end

    ##
    # apply str_no_lbreak and str_abbrev to +str+
    def str_abbrev_inline(str, length = 12)
      str_no_lbreak(str_abbrev(str, length))
    end

    module_function :str_no_lbreak, :str_abbrev, :str_abbrev_inline
    
  end # module String
  
end # module Rocc::Helpers
