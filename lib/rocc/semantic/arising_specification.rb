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

#require 'rocc/semantic/specification'

module Rocc::Semantic::Temporary

  class ArisingSpecification #< Rocc::Semantic::Specification

    attr_reader :origin, :symbol_family, :identifier, :storage_class, :type_qualifiers, :type_specifiers

    ##
    # +origin+ of a specification shall be an array of those tokens
    # that form this specification.
    def initialize(tokens)
      @origin = []
      extend_origin(tokens)
      @symbol_family = nil
      @identifier = nil
      @linkage = nil
      @storage_class = nil
      @type_qualifiers = []
      @type_specifiers = []
    end

    private
    def finish_class
      CeDeclaration
    end

    public
    def finish(branch)
      specification = finish_class.new(origin)
      symbol = branch.announce_symbol(specification, @symbol_family, @identifier, @linkage, @storage_class, @type_qualifiers, @type_specifiers)
    end

    def extend_origin(tokens)
      if tokens.is_a? Array
        @origin += tokens
      else
        @origin << tokens
      end
    end

    def symbol_family=(symbol_family)
      if @symbol_family and not symbol_family < @symbol_family
        raise "inconsistent symbol_familys detected"
      end
      @symbol_family = symbol_family     
    end

    def identifier=(identifier)
      raise "multiple identifiers" if @identifier
      @identifier = identifier
    end

    def linkage
      @linkage || :default
    end

    def linkage=(linkage)
      raise "inconsistent linkage" if linkage
      @linkage = linkage
    end

    def namespace
      @namespace || :default
    end

    def namespace=(namespace)
      raise "inconsistent namespace" if namespace
      @namespace = namespace
    end

    def storage_class=(storage_class)
      raise "multiple storage class specifiers" if storage_class
      @storage_class = storage_class
    end

    def add_type_qualifier(type_qualifier)
      warn "redundant type qualifier: #{type_qualifier}" if @type_qualifiers.include?(type_qualifier)
      @type_qualifiers << type_qualifier
    end

    def add_type_specifier(type_specifier)
      if not @type_specifiers.empty?
        no_prefix = @type_specifiers.find {|s| not [:short, :long, :signed, :unsigned].includes s }
        raise "inconsistent type specifiers: #{@type_specifiers.inspect} vs. #{type_specifier}" if no_prefix

        if @type_specifiers.includes?(type_specifier)
          warn "redundant #{type_specifier}" unless type_specifier == long and @type_specifiers.count(type_specifier) == 1 # XXX warn or raise ?!
        end

        case type_specifier
        when :short
          raise "inconsistent type specifiers" if @type_specifiers.includes?(:long)
        when :long
          raise "inconsistent type specifiers" if @type_specifiers.includes?(:short)
        when :signed
          raise "inconsistent type specifiers" if @type_specifiers.includes?(:unsigned)
        when :unsigned
          raise "inconsistent type specifiers" if @type_specifiers.includes?(:signed)
        when :char, :short, :int, :long
          # do nothing
        when :void, :float, :double, :bool, CeTypedef
          raise "inconsistent type specifiers" unless @type_specifiers.empty?
        else
          raise "invalid type specifier: `#{type_specifier}'"
        end
        
      end
      
      @type_specifiers << type_specifier
      
    end # add_type_specifier

    
  end # class ArisingSpecification

end # module Rocc::Semantic
