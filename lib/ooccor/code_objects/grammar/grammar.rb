# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects::Grammar

  # fixme: refactor -- split to separate files


  # forward declaration
  class GroTaggedDeclarationList < GrammarObject; end


  class GrammarObject < CodeObject

    def expand(env)
      nil
    end

  end # class GrammarObject

  class GroParenthesized < GrammarObject
  end # class GroParenthesized

  class GroBracketed < GrammarObject
  end # class GroBracketed

  #########
  # Following class names based on "Kernighan, Brian W.; Ritchie, Dennis M. The C Programming Language (2nd ed.)", appendix A ("Reference Manual"), esp. section A13 ("Grammar")
  #########

  class GroTranslationUnit < GrammarObject
  end # class GroTranslationUnit


  class GroFunctionDefinition < GrammarObject
    attr_reader :identifier
  end # class GroFunctionDefinition


  class GroDeclaration < GrammarObject

    attr_reader :declarators


    def initialize(origin)

      super(origin) # fixme: what if unbound_objects come from a macro expansion? derive origin from env instead!
      @declarators = []

    end # initialize


    def self.wrap_up(env, ctxt)

      GroDeclarationSpecifiers.wrap_up(env, ctxt)

      origin = ctxt[:unbound_objects] # fixme: what if unbound_objects come from a macro expansion? derive origin from env instead!

      obj = new(origin)
      ctxt[:unbound_objects][0,1] = obj
      ctxt[:grammar_stack] << obj

      obj.add_declarator(env, ctxt)

    end # wrap_up


    def add_declarator(env, ctxt)

      raise "assertion" unless ctxt[:grammar_stack].last == ctxt[:unbound_objects][0] and ctxt[:grammar_stack].last.is_a? GroDeclaration
      
      declarator = ctxt[:unbound_objects][1..-1]
      ctxt[:unbound_objects][1..-1] = []

      @declarators << declarator
      
      # todo: create and register the symbols being declared.

    end # add_item


    def finalize(env, ctxt)

      # todo: set @origin accordingly (or update continuously with add_item)

      raise "assertion" unless ctxt[:grammar_stack].pop == self
      ctxt[:grammar_stack].pop

    end # finalize

  end # class GroDeclaration


  class GroDeclarationSpecifiers < GrammarObject


    def self.wrap_up(env, ctxt)
      declarator_start = find_end(ctxt[:unbound_objects])
      origin = ctxt[:unbound_objects][0...declarator_start] # fixme: what if unbound_objects come from a macro expansion? derive origin from env instead!
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
        when TknKwTypeQualifier, TknKwStorageClassSpecifier
          FALSE
        when TknKwTypeSpecifier, GroTaggedSpecifier
          type_specifier_count += 1
          FALSE
        when TknKeyword
          raise
        when TknWord
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
        end
      else
        raise
      end

      declarator_start
    end # find_end


  end # class GroDeclarationSpecifiers


  # Handles structs *and* unions
  class GroStructDeclarationList < GroTaggedDeclarationList


  end # class GroStructDeclarationList


  class GroEnumeratorList < GroTaggedDeclarationList
  end # class GroEnumeratorList


  class GroCompoundStatement < GrammarObject
  end # class GroCompoundStatement


  #########
  # Following class names are less verbatim based on "The C Programming Language"
  #########


  # selection-statement and iteration-statement
  class GroControlStructure < GrammarObject
  end # class GroControlStructure


  # struct-or-union-specifier and enum-specifier
  class GroTaggedSpecifier < GrammarObject
  end # class GroTaggedSpecifier


  # struct-declaration-list and enumerator-list
  class GroTaggedDeclarationList < GrammarObject

    def self.pick!(env, ctxt)

      unbound = ctxt[:unbound_objects]

       if unbound.length >= 1 and unbound[-1].is_a? TknKwTagged
            keyword = unbound[-1]
            unbound[-1,1] = []
            grast << GroTaggedSpecifier.new(env, ctxt, keyword, nil)
            raise "todo"
            grast << GroStructDeclarationList / GroEnumeratorList

          elsif unbound.length >= 2 and unbound[-2].is_a? TknKwTagged and unbound[-1].is_a? TknWord
            keyword = unbound[-2]
            identifier = unbound[-1]
            unbound[-2,2] = []
            grast << GroTaggedSpecifier.new(env, ctxt, keyword, identifier)
            raise "todo"
            grast << GroStructDeclarationList / GroEnumeratorList
    end      
      
    end

  end # class GroTaggedDeclarationList


end # module Ooccor::CodeObjects::Grammar
