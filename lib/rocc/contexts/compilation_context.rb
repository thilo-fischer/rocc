# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::Contexts

  class CompilationContext

    attr_reader :parent, :tkn_cursor

    def initialize(parent, condition = nil)
      @parent = parent
      @children = []

      @condition = condition

      @tkn_cursor = nil

      #@macros = {}
      #@typedefs = {}
      @symbols = SymbolIndex.new
    end

    def branch(condition)
      b = new(self, condition)
      @children << b
   #   b.setup(self)
    end

    def conditions
      if root?
        raise "Programming error!" unless condition == nil
        []
      else
        @parent.conditions << condition
      end
    end
    
    def root?
      @parent.is_a? CoTranslationUnit
    end

    def find_symbol(name, ...)
      result = @symbols.find_symbol(...)
      return if result
      return @parent.find_symbol(...)
    end

    def terminate
      @parent.annouce_symbols(@symbols)
    end
    
#    def progress_token(tkn = nil, length)
#      @recent_token = tkn if tkn
#      @line_offset += length
#      @line_offset += @remainder.slice!(/^\s*/).length
#      @recent_token
#    end
#
#    private
#
#    def setup(master)
#      @tkn_cursor = master.tkn_cursor
#      ## XXX Which gives better performance? Copy the arrays and add to those copies or adding to empty arrays and collecting the elements of all arrays when looking for an entry?
#      #@macros = master.macros.dup
#      @symbols = master.symbols.branch
#    end

  end # class CompilationContext

end # module Rocc
