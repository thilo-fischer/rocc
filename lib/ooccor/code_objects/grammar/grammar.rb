# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects

  #  module Grammar

  # fixme: refactor -- split to separate files


  # forward declaration
  class GrammarObject            < CodeObject;    end
  class GroTaggedDeclarationList < GrammarObject; end
  class GroDeclaration           < GrammarObject; end


  class GrammarObject < CodeObject

    attr_reader :parent

    def initialize(origin, parent = nil)
      super(origin)
      @parent = parent
    end

    def expand(env)
      nil
    end

  end # class GrammarObject

  class GroParenthesized < GrammarObject

    def finalize(env, ctxt, terminator)
      # fixme: similar to GroDeclaration.finalize

      # todo: set @origin accordingly

      obj = ctxt[:grammar_stack].pop
      ctxt[:unbound_objects] << obj
      raise "assertion" unless obj == self

    end # finalize

  end # class GroParenthesized

  class GroBracketed < GrammarObject

    def finalize(env, ctxt, terminator)
      # fixme: redundant to GroParenthesized.finalize

      # todo: set @origin accordingly

      obj = ctxt[:grammar_stack].pop
      ctxt[:unbound_objects] << obj
      raise "assertion" unless obj == self

    end # finalize

  end # class GroBracketed

  #########
  # Following class names based on "Kernighan, Brian W.; Ritchie, Dennis M. The C Programming Language (2nd ed.)", appendix A ("Reference Manual"), esp. section A13 ("Grammar")
  #########

  class GroTranslationUnit < GrammarObject
  end # class GroTranslationUnit


  class GroFunctionDefinition < GroDeclaration # fixme: this inheritage has a smell

    attr_reader :identifier, :compound_statement

    def self.wrap_up(env, ctxt)

      obj = super # fixme: cannot handle `declaration-list'

      obj.verify_declaraiton_is_function_definition # fixme

      obj

    end # wrap_up

    def verify_declaraiton_is_function_definition

      raise "assertion" unless declarators.length == 1
      raise "assertion" unless declarators.first.length == 2

      case declarators.first[0]
      when Tokens::TknWord
        @identifier = declarators.first[0].text
      when GroParenthesized
        # function pointer
        raise "todo"
      else
        raise "assertion"
      end

      raise "assertion" unless declarators.first[1].is_a? GroParenthesized

    end # verify_declaraiton_is_function_definition

    def finalize(env, ctxt)
      # todo?: set @origin accordingly

      @compound_statement = ctxt[:unbound_objects].pop
      raise "assertion" unless @compound_statement.is_a? GroCompoundStatement
      raise "assertion" unless ctxt[:unbound_objects].empty?

      obj = ctxt[:grammar_stack].pop
      
      raise "assertion" unless obj == self

      obj

    end # finalize

    def list(format = :short)
      case format
      when :short
        "#{@identifier}()"
      else
        to_s
      end
    end
  

  end # class GroFunctionDefinition


  class GroDeclaration < GrammarObject

    attr_reader :declarators


    def initialize(origin)

      super(origin) # fixme: what if unbound_objects come from a macro expansion? derive origin from env instead!
      @declarators = []

    end # initialize


    def self.wrap_up(env, ctxt)

      GroDeclarationSpecifiers.wrap_up(env, ctxt)

      origin = CoContainer.new(ctxt[:unbound_objects])

      obj = new(origin)
      ctxt[:unbound_objects][0,1] = obj
      ctxt[:grammar_stack] << obj

      obj.add_declarator(env, ctxt)

      obj

    end # wrap_up


    def add_declarator(env, ctxt)

      raise "assertion" unless ctxt[:grammar_stack].last == ctxt[:unbound_objects][0] and ctxt[:grammar_stack].last.is_a? GroDeclaration
      
      declarator = ctxt[:unbound_objects][1..-1]
      ctxt[:unbound_objects][1..-1] = []

      @declarators << declarator
      @origin.append(declarator) # todo: add `,' or `;'
      
      # todo: create and register the symbols being declared.

    end # add_item


    def finalize(env, ctxt)

      obj = ctxt[:grammar_stack].pop
      raise "assertion" unless obj == self

    end # finalize

  end # class GroDeclaration


  class GroDeclarationSpecifiers < GrammarObject


    def self.wrap_up(env, ctxt)
      declarator_start = find_end(ctxt[:unbound_objects])
      origin = CoContainer.new(ctxt[:unbound_objects][0...declarator_start])
      obj = new(origin)
      ctxt[:unbound_objects][0...declarator_start] = obj
      ctxt[:grammar_stack] << obj
    end # wrap_up


    def self.find_end(obj_array)
      # fixme: makeshift that fails for `foo (bar)' function declarations
      type_specifier_count = 0
      first_identifier = nil

      declarator_start = obj_array.find_index do |o|
        case o
        when Tokens::TknKwTypeQualifier, Tokens::TknKwStorageClassSpecifier
          FALSE
        when Tokens::TknKwTypeSpecifier, GroTaggedSpecifier
          type_specifier_count += 1
          FALSE
        when Tokens::TknKeyword
          raise
        when Tokens::TknWord
          if type_specifier_count == 0
            first_identifier = o
            type_specifier_count += 1
          else
            TRUE
          end
        when GroParenthesized
          TRUE
        when Tkn1Char
          if o == "*"
            TRUE
          else
            raise
          end
        else
          raise
        end
      end

      unless declarator_start
        if first_identifier and first_identifier == obj_array.last
          declarator_start = obj_array.length - 1
        else
          raise
        end
      end

      declarator_start
    end # find_end


  end # class GroDeclarationSpecifiers


  # Handles structs *and* unions
  class GroStructDeclarationList < GroTaggedDeclarationList


  end # class GroStructDeclarationList


  class GroEnumeratorList < GroTaggedDeclarationList
  end # class GroEnumeratorList


  class GroStatement < GrammarObject

    def self.pick!(env, ctxt)

      # fixme: implemented properly ..? define `expand'?

      origin = CoContainer.new(ctxt[:unbound_objects])
      parent = ctxt[:grammar_stack].last
      
      obj = new(origin, parent)

      ctxt[:unbound_objects] = [] # fixme: smells

      obj

    end # pick

  end # class GroStatement

  class GroCompoundStatement < GrammarObject

    def finalize(env, ctxt, terminator)
      # fixme: similar to GroDeclaration.finalize

      # todo: set @origin accordingly

      obj = ctxt[:grammar_stack].pop
      
      ctxt[:unbound_objects] << obj

      raise "assertion" unless obj == self

    end # finalize

  end # class GroCompoundStatement


  #########
  # Following class names are less verbatim based on "The C Programming Language"
  #########


  # selection-statement and iteration-statement
  class GroControlStructure < GrammarObject
  end # class GroControlStructure


  # struct-or-union-specifier and enum-specifier
  class GroTaggedSpecifier < GrammarObject

    def initialize(env, ctxt, keyword, identifier = nil)

      super(keyword)      

      raise "TODO"

    end # initialize

    def self.pick!(env, ctxt)

      unbound = ctxt[:unbound_objects]
      
      if unbound.length >= 1 and unbound[-1].is_a? Tokens::TknKwTagged
        keyword = unbound[-1]
        identifier = nil
        unbound[-1..-1] = []
        
      elsif unbound.length >= 2 and unbound[-2].is_a? Tokens::TknKwTagged and unbound[-1].is_a? Tokens::TknWord
        keyword = unbound[-2]
        identifier = unbound[-1]
        unbound[-2..-1] = []

      else
        return nil

      end
      
      obj = GroTaggedSpecifier.new(env, ctxt, keyword, identifier)
      grast << obj
      obj

    end # pick!

  end # class GroTaggedSpecifier


  # struct-declaration-list and enumerator-list
  class GroTaggedDeclarationList < GrammarObject

    def self.pick!(env, ctxt)

      if specifier = GroTaggedSpecifier.pick!(env, ctxt)

        case specifier.text
        when "struct", "union"
          grast << GroStructDeclarationList.new(origin)
        when "enum"
          grast << GroEnumeratorList.new(origin)
        else
          raise
        end

        grast.last

      end

    end # pick!

  end # class GroTaggedDeclarationList


  # end # module Grammar

end # module Ooccor::CodeObjects::Grammar
