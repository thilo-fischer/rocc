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

require 'rocc/code_elements/code_element'

module Rocc::Semantic

  class CeSymbol < Rocc::CodeElements::CodeElement

    attr_reader :identifier, :adducers

    # origin is the unit the symbol lives in, e.g. the translation
    # unit it belongs to.  identifier is the symbols name.
    def initialize(origin, identifier, conditions, hashargs)
      raise "unprocessed hashargs: #{hashargs.inspect}" unless hashargs.empty? # XXX defensive progamming => remove some day
      super(origin)
      @identifier = identifier
      @existence_conditions = conditions
      log.fatal{"new symbol #{self} in #{origin} given #{conditions}"}
    end # initialize

    def name
      "symbol `#{@identifier}'"
    end
    
    def name_dbg
      "Sym[#{@identifier}]"
    end

    def match(criteria)
      #warn "XXXX #{name_dbg} -> match: #{criteria}"
      
      return true if criteria.empty? # shortcut to maybe safe performance. XXX remove?
      
      family = criteria.delete(:symbol_family)
      case
      when family == nil
        # nothing to test then
      when family.is_a?(Class)
        if family <= CeSymbol
          return false unless self.is_a?(family)
        else
          raise "invalid argument: :symbol_family => #{family.inspect}"
        end
      when family.is_a?(Array)
        return false unless family.find {|f| self.is_a?(f)}        
      else
        raise "invalid argument: :symbol_family => #{family.inspect}"
      end

      identifier = criteria.delete(:identifier)
      case identifier
      when nil
        # nothing to test then
      when String
        return false unless @identifier == identifier
      when Regexp
        return false unless @identifier =~ identifier
      else
        raise "invalid argument: :identifier => #{identifier.inspect}"
      end

      origin = criteria.delete(:origin)
      #warn "XXXX match #{name_dbg}, origin criterion: #{origin}"
      case origin
      when nil
        # nothing to test then
      when Rocc::CodeElements::CodeElement
        #warn "XXXX match #{name_dbg}.origin: Is #{@origin} == #{origin} ?"
        return false unless @origin == origin
      when Class
        return false unless @origin.is_a? origin
      else
        raise "invalid argument: :origin => #{origin.inspect}"
      end

      conditions = criteria.delete(:conditions)
      case conditions
      when nil
         # nothing to test then
      when Rocc::Semantic::CeCondition
        return false unless @existence_conditions.imply?(conditions)
      else
        raise "invalid argument: :condition => #{condition.inspect}"
      end

      #warn "#{name_dbg} -> match: #{criteria} => true"
      true
    end # def match(criteria)

    ##
    # Create a string representation of this symbol formatted
    # according to the provided format string.
    #
    # Format string works similar to the format strings used with the
    # commonly known strftime functions. The following format
    # directives can be used:
    #
    # = General Purpose
    # [%n] newline character
    # [%t] tab character
    # [%%] literal % character
    #
    # = All symbols
    # [%i] symbols identifier
    # [%f] one character indicating the symbol's family, as following:
    #      [f] function
    #      [v] variable
    #      [t] type (typedef)
    #      [m] (preprocessor) macro
    #      [s] struct
    #      [u] union
    #      [e] enum
    #      [c] class (planned with C++ support)
    #      [n] namespace (planned with C++ support)
    # [%F] Full name of the symbol's family
    # [%y] symbol's type for all symbols that natively have a type
    #      (like variables, functions) (including brackets to indicate
    #      array types,
    #      including numbers in brackets for fixed-sized arrays)
    # [%Y] symbol's type for all symbols where some type can be determined,
    #      e.g. assign type +int+ to a macro +#define m 42+, type
    #      +unsigned long int+
    #      to a macro +#define m 42ul+
    #
    # = Parameters
    # Have effect on symbols with parameters only, i.e. funtions and
    # function
    # style macros only. Will be an in empty string for any other symbols.
    # [%0P]  number of parameters
    # [%>P]  number of parameters if at least one parameter, empty
    #        string otherwise
    # [%)P]  number of parameters in parenthesis
    # [%\]P] number of parameters in parenthesis if if at least
    #        one parameter,
    #        empty parenthesis otherwise
    # [%}P]  number of parameters in parenthesis if if at least
    #        one parameter, 0 if void is given within the function
    #        signature's parenthesis (FIXME: WHICH signature?!),
    #        empty parenthesis otherwise
    # [%,P]  comma-separated list of parameter types (includes one
    #        space character after each comma)
    # [%.p]  The . may be any character or sequence of characters.
    #        This character
    #        (sequence) will be put literally to the result string if
    #        the symbol has parameters. ('p' cannot not be this character
    #        or in the
    #        character sequence.)
    #
    # = Formatting
    # [%nC] Add space characters until the string is n characters long,
    #       n is an integer number.
    #
    def strf(format = '%f %i%}P')
      format = format.split('%')
      format.inject do |result, part|
        directive = part.slice!(/[^A-Za-z]*[A-Za-z]/)
        subst = case directive
                when 'n'
                  '\n'
                when 't'
                  '\t'
                when '%'
                  '%'
                when 'i'
                  identifier
                when 'f'
                  self.class.family_character
                when 'f'
                  self.class.family_name
                when 'y'
                  raise "not yet implemented" # FIXME
                  type_string
                when 'Y'
                  raise "not yet implemented" # FIXME
                  imposed_type_string
                when '0P'
                  if self.respond_to? :parameters and parameters
                    parameters.count.to_s
                  else
                    ''
                  end
                when '>P'
                  if self.respond_to? :parameters and parameters and not parameters.empty?
                    parameters.count.to_s
                  else
                    ''
                  end
                when ')P'
                  if self.respond_to? :parameters and parameters
                    "(#{parameters.count.to_s})"
                  else
                    ''
                  end
                when ']P'
                  if self.respond_to? :parameters and parameters
                    if parameters.empty?
                      '()'
                    else
                      "(#{parameters.count.to_s})"
                    end
                  else
                    ''
                  end
                when '}P'
                  if self.respond_to? :parameters and parameters
                    if parameters.empty? and not self.signatures.find {|s| s.is_void?}
                      '()'
                    else
                      "(#{parameters.count.to_s})"
                    end
                  else
                    ''
                  end
                when ',P'
                  if self.respond_to? :parameters and parameters
                    raise "not yet implemented" # FIXME
                    parameters.map {|p| p.type_string}.join(', ')
                  else
                    ''
                  end
                when /.*?p/
                  if self.respond_to? :parameters and parameters
                    directive.chop
                  else
                    ''
                  end
                when /\d+C/
                  targetlen = directive.chop.to_i
                  if targetlen > result.length
                    (targetlen - result.length) * ' '
                  else
                    ''
                  end
                else
                  raise "invalid strf directive: `%#{directive}'"
                end
        result + subst + part
      end
    end

    private

    def pick_from_hashargs(hashargs, key_symbol)
      raise "Cannot find `#{key_symbol}' in #{hashargs.inspect}" unless hashargs.key? key_symbol # XXX defensive progamming => remove some day
      value = hashargs[key_symbol]
      hashargs.delete(key_symbol) # XXX defensive progamming => remove some day
      value
    end

  end # class CeSymbol

end # module Rocc::Semantic
