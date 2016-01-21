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

require 'rocc/semantic/specification'
require 'rocc/semantic/declaration'
require 'rocc/semantic/definition'
#require 'rocc/semantic/typedef'

module Rocc::Semantic::Temporary

  ##
  # Gathers information on a specification while the specification is
  # being parsed and not yet parsed to an extend where the final
  # CeSpecification and CeSymbol object can be initialized.
  #
  # +origin+ is an array of those tokens that form this
  # specification. +origin_shared+ are those tokens that might be
  # "reused" in another specification, +origin_private+ are those
  # tokens specific to this specification. E.g. in +volatile const
  # unsigned int foo, (*bar), baz();+, +volatile const unsigned int+
  # is the shared origin of the specifications of foo, bar, baz, while
  # +foo+, +(*bar)+ and +baz()+ are the private origin tokens.
  #
  # Implementation stores reference to the tokens *plus* symbols
  # queried from the tokens. This brings in some redundancy (storing
  # the tokens would be sufficient to gather the symbols from them on
  # demand), but it increases performance because all symbols will be
  # needed on finalization of the +ArisingSpecification+ anyways.
  class ArisingSpecification #< Rocc::Semantic::Specification

    attr_reader :origin_shared, :origin_private, :symbol_family, :identifier, :storage_class, :type_qualifiers, :type_specifiers

    def initialize
      @origin_shared = []
      @origin_private = []
      @symbol_family = nil
      @identifier = nil
      @storage_class = nil
      @type_qualifiers = []
      @type_specifiers = []
      @specification_type = Rocc::Semantic::CeSpecification
    end

    def origin
      @origin_shared + @origin_private
    end
    
    def finalize(branch)
      raise "CeSpecification is abstract class" if @specification_type == Rocc::Semantic::CeSpecification # FIXME rework @specification_type
      specification = @specification_type.new(origin)
      @symbol = create_symbol(specification) unless @symbol
      @symbol.add_adducer(specification)
      @symbol
    end

    def create_symbol(branch)
      raise "Already created symbol from this #{self.class}!" if @symbol
      hashargs = {}
      hashargs[:storage_class] = @storage_class if @storage_class
      hashargs[:type_qualifiers] = @type_qualifiers unless @type_qualifiers.empty?
      hashargs[:type_specifiers] = @type_specifiers unless @type_specifiers.empty?
      @symbol = branch.announce_symbol(branch.closest_symbol_origin_scope, @symbol_family, @identifier, hashargs)
      @symbol
    end

    private
    def extend_origin(tokens)
      if tokens.is_a? Array
        @origin += tokens
      else
        @origin << tokens
      end
    end
    
    public
    def symbol_family=(symbol_family)
      if @symbol_family and not symbol_family < @symbol_family
        raise "inconsistent symbol_familys detected"
      end
      @symbol_family = symbol_family     
    end

    def set_identifier(token)
      raise "multiple identifiers" if @identifier
      @origin_private << token
      @identifier = token.text
      @type_specifiers = [:implicit] if @type_specifiers.empty?
    end

    def set_storage_class(token)
      raise "multiple storage class specifiers" if storage_class
      raise "storage class specifier cannot occur after identifier" if @identifier
      @origin_shared << token
      @storage_class = token.storage_class_symbol
    end

    def add_type_qualifier(token)
      raise "type qualifier cannot occur after identifier" if @identifier
      @origin_shared << token
      symbol = token.type_qualifier_symbol
      warn "redundant type qualifier: #{symbol}" if @type_qualifiers.include?(symbol)
      @type_qualifiers << symbol
    end

    def add_type_specifier(token)
      raise "type specifier cannot occur after identifier" if @identifier
      symbol = token.type_specifier_symbol
      if not @type_specifiers.empty?
        no_prefix = @type_specifiers.find {|s| not [:short, :long, :signed, :unsigned].includes s }
        raise "inconsistent type specifiers: #{@type_specifiers.inspect} vs. #{symbol}" if no_prefix

        if @type_specifiers.includes?(symbol)
          warn "redundant #{symbol}" unless symbol == long and @type_specifiers.count(symbol) == 1 # XXX warn or raise ?!
        end

        case symbol
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
        when :void, :float, :double, :bool, Rocc::Semantic::CeTypedef
          raise "inconsistent type specifiers" unless @type_specifiers.empty?
        else
          raise "invalid type specifier: `#{symbol}'"
        end
        
      end

      @origin_shared << token
      @type_specifiers << symbol
      
    end # add_type_specifier

    def mark_as_definition
      @specification_type = Rocc::Semantic::CeDefinition
    end

    def mark_as_declaration
      @specification_type = Rocc::Semantic::CeDeclaration
    end

    private

    def specification_type=(st_arg)
      raise if @specification_type and not st_arg < @specification_type
      @specification_type = st_arg
    end

    public
    
    def is_definition?
      case @specification_type
      when CeDefinition
        true
      when CeDeclaration
        false
      when CeSpecification
        nil
      else
        raise "programming error"
      end
    end

    def is_declaration?
      case @specification_type
      when CeDefinition
        false
      when CeDeclaration
        true
      when CeSpecification
        nil
      else
        raise "programming error"
      end
    end

    def name_dbg
      "ASpec[#{@identifier}]"
    end
    
  end # class ArisingSpecification

end # module Rocc::Semantic
