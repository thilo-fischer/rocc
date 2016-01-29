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
    # origin is the associated function, adducer is the opening
    # parenthesis token
    def initialize(origin, adducer)
      super(origin)
      @param_names = []
      @adducer = [adducer]
      @void = nil
    end

    def add_param(type, name, storage_class_specifier = nil)
      raise "register is the only storage class specifier allowed for function parameters" if storage_class_specifier and storage_class_specifier != :register

      @void = false
      
      @param_names << name
      
      if function.param_list_complete?
        # TODO assert type is the same as the one of the function's already existing parameter
      else
        function.announce_parameter(@param_names.count, type, storage_class_specifier)
      end
      
    end # sdd_param

    def complete?
      adducer.count == 2
    end

    # add closing parenthesis token
    def close(token)
      adducer << token
      raise if function.param_list_complete? # XXX only for debugging => remove
      function.param_list_finalize
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
      @void
    end
    
  end # class CeFunction

end # module Rocc::Semantic
