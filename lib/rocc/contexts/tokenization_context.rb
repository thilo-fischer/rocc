# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  class LinereadContext

    attr_reader :recent_token

    def initialize(root_context)
      @root_context = root_context
      @recent_token = nil
    end

    def progress_token(tkn = nil, length)
      @recent_token = tkn if tkn
      @line_offset += length
      @line_offset += @remainder.slice!(/^\s*/).length
      @recent_token
    end

  end # class LinereadContext

end # module Rocc
