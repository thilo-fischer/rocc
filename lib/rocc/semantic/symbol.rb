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
      log.info{"new symbol #{self} in #{origin} given #{conditions}"}
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
    # This function is for symbols similar to what the commonly known
    # strftime functions are to time and date data.
    #
    # Format string works similar to the format strings used with the
    # printf and strftime functions. A format string may contain
    # "ordinary characters", conversion specifiers, conditional
    # sections, conversion extensions and special character
    # specifiers.
    # 
    # * Ordinary characters are the same as ordinary characters in
    #   printf and strftime functions: Any characters other than
    #   %. All ordinary characters will be copied literally from the
    #   format string to the result string.
    # 
    # * Conversion specifiers are very similar to the conversion
    #   specifiers known from printf function. Conversion specifiers
    #   from the format string will get replaced in the result string
    #   with strings that represent certain information from the
    #   symbol the strf function is being invoked on in the format
    #   specified by the conversion specifier. The string to replace a
    #   conversion specifier in the result string will in the
    #   following be refered to as its <em>replacement string</em>. A
    #   conversion specifiers always starts with a % character
    #   followed by zero or more flags, an optional minimum width and
    #   an optional maximum width specification and a conversion
    #   specifier character. See below for details.
    #
    # * Conditional sections are special for the format strings as
    #   supported by this function. They have a start mark, and
    #   optinal else mark and an end mark which enclose regular format
    #   string content. The content will be part of the result string
    #   only if certain conditions as specified by the start mark
    #   apply. They start with the characters %? followed by zero or
    #   more flags, a condition specifier character and a {
    #   character, followed by arbitrary format string content, TODO>
    #   optinally followed by %?flags_condition| (-> elsif) or %| (->
    #   else) <TODO and end with the characters %}. See below for
    #   details.
    #
    # * Conversion extensions are special for the format strings as
    #   supported by this function. They consist of a % character and
    #   arbitrary other characters and have special meaning. See below
    #   for details.
    #
    # * Special character specifiers can be used in the format string
    #   to specifiy when non-ordinary characters (i.e. the %
    #   character) and other special characters shall be put in the
    #   result string.
    #
    # = Conversion specifiers
    #
    # == Flags
    #
    # [-] The replacement string shall be left-adjusted. (Default is
    #     right-adjusted.)
    #
    # [|] If the replacement string is being truncated due to the
    #     maximum width value, just truncate it to a length of maximum
    #     width characters. (Default is to truncate it to maximum
    #     width - 1 characters and to append the UTF-8 ellipsis
    #     character to mark that a truncation was done.)
    #
    # [' ']
    #     (space character) If the conversion specifier character is
    #     not applicable to the current symbol and a minimum width
    #     vaule is given, use minimum width number of space
    #     characters as replacement string. (Default is to use empty
    #     replacement string if conversion specifier character is
    #     not applicable.)
    #
    # [^] Fill part of the replacement string or the overall
    #     replacement string only if the value from which the
    #     replacement string's content is being created is not
    #     trivial, empty, null, zero or similar. This flag has
    #     different meaning for different conversion specifier
    #     characters, specifically:
    #     
    #     [p, q, P]
    #         Add only if function or macro has at least one parameter.
    #
    #     [c] Add only if symbol exists only under certain conditions
    #         (i.e. existence conditions of the symbol are not
    #         CeUnconditionalCondition).
    #
    #     [C] Add only if there is a certain probability for the
    #         symbol to exist, i.e. the symbol is not specified within
    #         a trivially unreachable preprocessor conditional branch
    #         like a <tt>#if 0</tt> or a <tt>#else</tt> of a <tt>#if
    #         1</tt>.
    #
    # [?] Make this conversion specifier affecting the activation of
    #     the encloing conditional section part. Activate encloing
    #     conditional section part if the conversion specifier
    #     character is applicable to the symbol and the value from
    #     which the replacement string's content is to be created is
    #     not trivial, empty, null, zero or similar. This flag has
    #     different meaning for different conversion specifier
    #     characters, analogue to the conversion specifier character
    #     specific significances of the ^ flag. See ^ flag and
    #     Conditional Sections for details.
    #
    # [!] Like ? flag, but use the content the conversion specifier
    #     refers to only to evaluate which parts of the conditional
    #     section to include in the result string, do not generate any
    #     replacement string for this conversion specifier.
    #     
    # [{, }, :]
    #     Not a flag, reserved for conditional sections (see
    #     below).
    #
    # [(]
    #     Not a flag, reserved for conversion extersions (see
    #     below).
    #
    # [~] If the replacement string contains characters to be prefixed
    #     and/or suffixed to the characters containing the actual
    #     content representing the symbol's value(s) and a minumum
    #     width value is given, align the prefix at the beginning of
    #     the conversion specifiers position in the replacement string
    #     and the suffix such that the overall replacement string is
    #     (at least) minimum width characters long.
    #
    # [#] Alternate form. This flag has different meaning for
    #     different conversion specifier characters, specifically:
    #
    #     [p, q]
    #         Always give +void+ for functions with no parameters.
    #
    #     [P] If used together with the ^ flag: Add 0 to the
    #         replacement string if function has no parameters but
    #         +void+ was given in the function's "most relevant"
    #         function signature.
    #
    #     [c] When used in combination with _ flag: Do *not* assume
    #         stdbool.h or C++, use +1+ and +0+ instead of +true+ and
    #         +false+.
    #
    # [_] Use replacement string that resembles target language
    #     (i.e. C, C++) code as close as possible.  This flag has
    #     different meaning for different conversion specifier
    #     characters, specifically:
    #     
    #     [C] Use && and || instead of UTF-8 characters for logical
    #         conjunction and disjunction.
    #
    # == Minimum Width
    #
    # The minimal width may be given as an integer number following
    # the flags (or following the % if no flags have been
    # specified). If given and the replacement string has less
    # characters than the given value, the value will be padded
    # (according to the flags given with whitespace to its right or
    # left side) until reaching the given number of characters. The
    # replacement string will not be truncated due to the minimal
    # width value. (See also - flag.)
    #
    # == Maximum Width
    #
    # The maximum width may be given as a . character followed by an
    # integer number (analogue to the precision of printf). It works
    # similar to to the precision of printf when applied to printf's
    # +s+ conversion specifier: If the replacement string has more
    # characters than the maximum width value, the replacement string
    # will be truncated to have no more than maximum width
    # characters. (See also \] flag.)
    #
    # == Conversion Specifier Characters
    #
    # Not all conversion specifier characters are applicable to all
    # sorts of symbols. The following subsections group the characters
    # according to their purpose and also according to the groups of
    # symbols to which they are applicable.
    #
    # When a conversion specifier is used on a symbol where its
    # conversion specifier character is not applicable, the
    # replacement string will be an empty string or if the ' ' (space)
    # flag and a minimum width value was given minimum width number of
    # spaces. (See also ' ' flag.)
    #
    # === All symbols
    # 
    # [i] symbols identifier
    # 
    # [f] one character indicating the symbol's family, as following:
    #     [f] function
    #     [v] variable
    #     [t] type (typedef)
    #     [m] (preprocessor) macro
    #     [s] struct
    #     [u] union
    #     [e] enum
    #     [c] class (not yet, planned C++ support)
    #     [n] namespace (not yet, planned C++ support)
    #      
    # [F] Full name of the symbol's family
    # 
    # [y] symbol's type for all symbols that natively have a type
    #     (like variables, functions) (including brackets to indicate
    #     array types, including numbers in brackets for fixed-sized
    #     arrays)
    #      
    # [Y] symbol's type for all symbols where some type can be
    #     determined, e.g. assign type +int+ to a macro +#define m
    #     42+, type +unsigned long int+ to a macro +#define m 42ul+
    #
    # === Parameters
    # 
    # Have effect on symbols with parameters only, i.e. funtions and
    # <em>function style</em> macros only. Will be an in empty string
    # or spaces for any other symbols.
    # 
    # [p] Comma-separated list of parameters, giving the parameter
    #     types for functions and parameter names for macros. Will be
    #     empty string if function or macro does not have any
    #     parameters. (Comma-space-separated list, to be more
    #     accurate, each comma is suffixed by one space character.)
    # 
    # [P] Number of parameters. Will be zero if function or macro
    #     does not have any parameters.
    #
    # [q] Like p, but for functions giving the parameter types and
    #     parameter names of the "most revevant" function signature
    #     and giving +void+ for functions with no parameters if +void+
    #     was given in the function's "most relevant" function
    #     signature.
    #
    # === Conditions
    #
    # [c] Existence conditions of the symbol.
    # 
    # [C] A probability value for the symbol's existence conditions to
    #     apply based on the assumption that every preprocessor
    #     conditional that is not trivial (like e.g. <tt>#if 0</tt>,
    #     <tt>#if 1</tt> or include guards) has a 50% chance to
    #     apply. Exact meaning of the vaule might change in future,
    #     but meaning when combinend with the ^ flag should be
    #     preserved.
    #
    # === Special Purpose
    #
    # [T] Adjust the lenght of the result string. To be used with
    #     minimum and/or maximum width values. If minimum width is
    #     given, and the result string is not yet as long as the given
    #     value, add space characters until reaching the given
    #     length. If maximum width is given, and the result string
    #     exceeds this length, truncate the result string. Truncation
    #     will be done according to the | flag.
    #
    # = Conditional Sections
    #
    # Conditional sections provide a basic "if-then-else" mechanism
    # for conditions based on the validity and applicability of
    # information from the symbol.
    #
    # A conditional section always starts with a %{, may contain zero
    # or more %: and ends with a %}. %{, %: and %} are the markers of
    # a conditional section. In between these markers may be any
    # regular format string content (including nested conditional
    # sections). The content in between two markers is one _part_ of
    # the conditional section. A conditional section in the format
    # string will be replaced in the result string with either the
    # result text of one of its parts or with an empty string
    # (i.e. will be left away).
    #
    # The first of the part of a conditional section containing a
    # conversion specifier (not inside a nested conditional section)
    # which has the ? or the ! flag set and where the content this
    # conversion specifier refers to is not trivial, empty, null, zero
    # or similar (as specified with the ^ flag) will be selected to be
    # used as a replacement for the overall conditional section. If
    # the last part of a conditional section does not contain a
    # conversion specifier (not inside a nested conditional section)
    # which has either the ? or the ! flag set and no previous part
    # got selected, the last part will be selected.
    #
    # = Conversion Extensions
    #
    # [(] Enclose the replacement text of the immediatly following
    #     conversion specifier in parenthesis. Can be combined with
    #     the following flags:
    #
    #     [^] Do not put parenthesis to the result string if the
    #         following conversion specifier uses the ^ flag and its
    #         replacement string is not filled with content of the
    #         symbol due to empty content and the ^ flag.
    #
    #     [~] When leaving away parenthisis due to the ^ flag, put a
    #         space character in the replacement string instead. (Two
    #         space characters if combined with the ' ' flag.)
    #
    #     [' '] (space character) Put one space character in between
    #           the following conversion specifier's replacement text
    #           and the enclosing parenthesis.
    #
    #     [{, \[, <, ', ", `, *] Use braces, brackets, angle brackets,
    #         (plain) single or double quotes, grave-accent/apostrophe
    #         style quotes or C comment delimitiers (+/*+, +*/+)
    #         instead of parenthesis.
    #
    # = Special Character Specifiers
    # 
    # [%%] literal % character
    # 
    # [%n] newline character
    # 
    # [%t] tab character
    #
    #
    def strf(format = "%f %i%^#P%{%T40\u2194 %?C%}")
      raise "DEPRECATED"
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
