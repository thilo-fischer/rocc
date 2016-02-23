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

require 'rocc/semantic/function'

module Rocc::Semantic::Temporary

  # TODO This is *not* a function signature (as it does not specify
  # anything about the function's return type). Rename to
  # "FunctionParameters" or such.
  class CeFunctionSignature < Rocc::CodeElements::CodeElement

    class Parameter
      attr_accessor :type, :name, :storage_class_specifier
      def initialize(type, name, storage_class_specifier)
        @type = type
        @name = name
        @storage_class_specifier = storage_class_specifier
      end        
    end

    alias function origin

    attr_reader :params

    ##
    # +origin+ is an array of all those tokens thate make up the
    # function signature (including the opening and closing
    # parenthesis)
    #
    # +first_tkn+ is the token of the opening parenthesis
    def initialize(first_tkn)
      super([first_tkn])
      @params = []
      @void = nil
      @complete = false
    end

    def name_dbg
      "FSig[#{@params.count}]"
    end    

    def add_param(tokens, type, name, storage_class_specifier = nil)
      @origin += tokens
      @params << Parameter.new(type, name, storage_class_specifier)
      
      raise "register is the only storage class specifier allowed for function parameters" if storage_class_specifier and storage_class_specifier != :register # XXX(assert)
      
    end # add_param

    def complete?
      @complete
    end

    # add closing parenthesis token
    def close(token)
      @origin << token
      @complete = true
    end

    def opening
      @origin.first
    end
    
    def closing
      @origin.last
    end

    ##
    # mark function signature as signature with no parameters that
    # explicitly states `void' for its function parameters (like
    # <tt>int foo(void);</tt>).
    #
    # +token+ The token that represents the void keyword.
    def mark_as_void(token)
      @origin << token
      @void = true
    end

    ##
    # returns +true+ if function has no parameters and signature is
    # like +func(void)+, +false+ if signature is like +func()+ or if
    # function has parameters, returns +nil+ if function signature has
    # not yet been parsed to a point where it is known whether the one
    # or the other applies.
    def is_void?
      (@void == true) if complete?
    end
    
  end # class CeFunctionSignature

end # module Rocc::Semantic::Temporary
