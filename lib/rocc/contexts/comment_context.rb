# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  class CommentContext

    attr_reader :multiline_comment

    def initialize
      @multiline_comment = nil
    end
    
    def announce_multiline_comment(comment)
      @multiline_comment ||= comment
    end

    def leave_multiline_comment
      @multiline_comment = nil
    end

  end # class CommentContext

end # module Rocc
