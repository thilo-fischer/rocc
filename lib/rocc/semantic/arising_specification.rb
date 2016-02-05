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
require 'rocc/semantic/function'
require 'rocc/semantic/variable'
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
      @symbol_family = Rocc::Semantic::CeSymbol
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
      @symbol = create_symbol(branch) unless @symbol
      specification = @specification_type.new(origin)
      @symbol.add_adducer(specification)
      @symbol
    end

    def create_symbol(branch)
      warn "ArisingSpecification#create_symbol(#{branch.name_dbg}) <- #{@identifier}"
      raise "missing identifier" unless @identifier
      raise "missing symbol_family" unless @symbol_family
      raise "Already created symbol from this #{self.class}!" if @symbol
      hashargs = {}
      hashargs[:storage_class] = @storage_class if @storage_class
      hashargs[:type_qualifiers] = @type_qualifiers unless @type_qualifiers.empty?
      hashargs[:type_specifiers] = @type_specifiers unless @type_specifiers.empty? # XXX this would be the better place to set type specififer :implicit if no type specifier is given ...
      origin = branch.closest_symbol_origin_scope
      @symbol = branch.announce_symbol(origin, @symbol_family, @identifier, hashargs)
      @symbol
    end

    def share_origin(other)
      @origin_shared = other.origin_shared
      # ensure we don't accidently change shared origin and implizitly
      # alter other
      @origin_shared.freeze
      
      @storage_class = other.storage_class
      @type_qualifiers = other.type_qualifiers
      @type_specifiers = other.type_specifiers
    end
    
    #def origin_shared=(arg)
    #  raise unless @origin_shared.empty?
    #  @origin_shared = arg
    #  @origin_shared.freeze
    #end

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
      @storage_class = token.storage_class_specifier_symbol
    end

    def add_type_qualifier(token)
      raise "type qualifier cannot occur after identifier" if @identifier
      @origin_shared << token
      symbol = token.type_qualifier_symbol
      log.warn{"redundant type qualifier: #{symbol}"} if @type_qualifiers.include?(symbol)
      @type_qualifiers << symbol
    end

    def add_type_specifier(token)
      raise "type specifier #{token.name_dbg} cannot occur after identifier `#{@identifier}'" if @identifier
      symbol = token.type_specifier_symbol
      if not @type_specifiers.empty?
        no_prefix = @type_specifiers.find {|s| not [:short, :long, :signed, :unsigned].include? s }
        raise "inconsistent type specifiers: #{@type_specifiers.inspect} vs. #{symbol}" if no_prefix

        if @type_specifiers.include?(symbol)
          log.warn{"redundant #{symbol}"} unless symbol == :long and @type_specifiers.count(symbol) == 1 # XXX warn or raise ?!
        end

        case symbol
        when :short
          raise "inconsistent type specifiers" if @type_specifiers.include?(:long)
        when :long
          raise "inconsistent type specifiers" if @type_specifiers.include?(:short)
        when :signed
          raise "inconsistent type specifiers" if @type_specifiers.include?(:unsigned)
        when :unsigned
          raise "inconsistent type specifiers" if @type_specifiers.include?(:signed)
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

    def specification_type=(arg)
      raise if @specification_type and not arg < @specification_type
      @specification_type = arg
    end

    public
    
    def is_definition?
      case
      when @specification_type <= Rocc::Semantic::CeDefinition
        true
      when @specification_type <= Rocc::Semantic::CeDeclaration
        false
      when @specification_type <= Rocc::Semantic::CeSpecification
        nil
      else
        raise "programming error, @specification_type: #{@specification_type}"
      end
    end

    def is_declaration?
      case
      when @specification_type <= Rocc::Semantic::CeDefinition
        false
      when @specification_type <= Rocc::Semantic::CeDeclaration
        true
      when @specification_type <= Rocc::Semantic::CeSpecification
        nil
      else
        raise "programming error, @specification_type: #{@specification_type}"
      end
    end

    # XXX? support symbol family CeFunctionParameter
    
    def mark_as_function
      @symbol_family = Rocc::Semantic::CeFunction
    end

    def mark_as_variable
      @symbol_family = Rocc::Semantic::CeVariable
    end

    private

    def symbol_family=(arg)
      raise if @symbol_family and not arg < @symbol_family
      @symbol_family = arg
    end

    public
    
    def is_function?
      case
      when @symbol_family <= Rocc::Semantic::CeFunction
        true
      when @symbol_family <= Rocc::Semantic::CeVariable
        false
      when @symbol_family <= Rocc::Semantic::CeSymbol
        nil
      else
        raise "programming error, @symbol_family: #{@symbol_family}"
      end
    end

    def is_variable?
      case
      when @symbol_family <= Rocc::Semantic::CeFunction
        false
      when @symbol_family <= Rocc::Semantic::CeVariable
        true
      when @symbol_family <= Rocc::Semantic::CeSymbol
        nil
      else
        raise "programming error, @symbol_family: #{@symbol_family}"
      end
    end

    def name_dbg
      "ASpec[#{@identifier}]"
    end
    
  end # class ArisingSpecification

end # module Rocc::Semantic::Temporary
