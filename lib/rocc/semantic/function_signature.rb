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

require 'rocc/semantic/function'

module Rocc::Semantic

  class CeFunctionSignature < Rocc::CodeElements::CodeElement

    alias function origin

    attr_reader :adducer, :param_names

    ##
    # origin is the associated function, adducer is an array of all
    # those tokens thate make up the function signature (including the
    # opening and closing parenthesis)
    def initialize(origin, adducer)
      super(origin)
      @param_names = []
      @adducer = [adducer]
      @void = nil
      @complete = false
    end

    def add_param(tokens, type, name, storage_class_specifier = nil)
      @adducer += tokens
      
      @param_names << name
      
      if function.param_list_complete?
        # TODO assert type is the same as the one of the function's already existing parameter
      else
        function.announce_parameter(@param_names.count, type, storage_class_specifier)
      end
      
      raise "register is the only storage class specifier allowed for function parameters" if storage_class_specifier and storage_class_specifier != :register
    end # sdd_param

    def complete?
      @complete
    end

    # add closing parenthesis token
    def close(token)
      adducer << token
      function.param_list_finalize # XXX smells: missleading function names when function has multiple signatures
      @complete = true
    end

    def opening
      adducer.first
    end
    
    def closing
      adducer.last
    end

    def mark_as_void
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
    
  end # class CeFunction

end # module Rocc::Semantic
