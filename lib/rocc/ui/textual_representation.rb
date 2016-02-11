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

require 'set' # needed if @flags are a set

require 'rocc/helpers'

module Rocc::Ui

  class SymbolFormatter

    ##
    # Create a string representation of +symbol+ formatted
    # according to the provided format string +format_str+.
    #
    # *WARNING:* Not all features of the format string as described
    # here are yet fully implemented! (=> TODO_W)
    #
    # This function is to symbols similar to what is the commonly
    # known strftime functions are to time and date data.
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
    # [~] If the conversion specifier character is not applicable to
    #     the current symbol and a minimum width vaule is given, use
    #     minimum width number of space characters as replacement
    #     string. (Default is to use empty replacement string if
    #     conversion specifier character is not applicable.)
    #
    # [+] Fill the replacement string only if the value from which the
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
    #     specific significances of the + flag. See + flag and
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
    # [#] Alternate form. This flag has different meaning for
    #     different conversion specifier characters, specifically:
    #
    #     [p, q]
    #         Always give +void+ for functions with no parameters.
    #
    #     [P] If used together with the + flag: Add 0 to the
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
    # replacement string will be an empty string or if the ~ flag and
    # a minimum width value was given minimum width number of
    # spaces. (See also ~ flag.)
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
    #     but meaning when combinend with the + flag should be
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
    #     will be done according to the | flag. T stands for Tabstop.
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
    # or similar (as specified with the + flag) will be selected to be
    # used as a replacement for the overall conditional section. If
    # the last part of a conditional section does not contain a
    # conversion specifier (not inside a nested conditional section)
    # which has either the ? or the ! flag set and no previous part
    # got selected, the last part will be selected.
    #
    # = Conversion Extensions
    #
    # [(] Enclose the replacement text of the immediatly following
    #     conversion specifier in parenthesis. May be prefixed with
    #     zero or more of the following flags:
    #
    #     [^] Do not put parenthesis to the result string if the
    #         following conversion specifier is not applicable to the
    #         symbol.
    #     
    #     [+] Do not put parenthesis to the result string if the
    #         following conversion specifier uses the + flag and its
    #         replacement string is not filled with content of the
    #         symbol due to empty content and the + flag.
    #
    #     [~] When leaving away parenthisis due to the + flag, put a
    #         space character in the replacement string instead. (Two
    #         space characters if combined with the ' ' flag.)
    #
    #     [' '] (space character) Put one space character in between
    #           the following conversion specifier's replacement text
    #           and the enclosing parenthesis.
    #
    #     [#, \[, <, ', ", `, *] Use braces, brackets, angle brackets,
    #         (plain) single or double quotes, grave-accent/apostrophe
    #         style quotes or C comment delimitiers (+/*+, +*/+)
    #         instead of parenthesis. (# flag is used to specifiy
    #         braces as { cannot be used as a flag because it is
    #         already used for conditional sections.)
    #
    # = Special Character Specifiers
    # 
    # [%%] literal % character
    # 
    # [%n] newline character
    # 
    # [%t] tab character
    #
    def self.format(format_str = DEFAULT_FORMAT_STR, symbol)
      formatter = compile(format_str)
      formatter.format(symbol)
    end # def self.format

    ##
    # Create a SymbolFormatter that will format a symbol passed to its
    # format method (its instance menthod SymbolFormatter#format, not
    # the class method SymbolFormatter.format) according to the format
    # string passed to the compile method.
    #
    # This way, the format string has to be parsed only once and can
    # afterwards be used for multipls symbols without needing to parse
    # the format string again.
    #
    # FIXME_R currently only a wrapper to SymbolFormatter.new ->
    # remove compile, use new instead? Or keep as synonym as Regexp
    # does it?
    def self.compile(format_str = DEFAULT_FORMAT_STR)
      new(format_str)
    end # def self.compile

    DEFAULT_FORMAT_STR = "%f %i%^(%+#P%{%32T[%?C]%}"

    FLAG_ADJUST_LEFT       = '-'
    FLAG_PLAIN_TRUNCATE    = '|'
    FLAG_APPLICABLE        = '^'
    FLAG_NO_TRIVIAL        = '+'
    FLAG_AFFECT_COND_SECT  = '?'
    FLAG_SELECT_COND_SECT  = '!'
    FLAG_FILL_WIDTH        = '~'
    FLAG_ALTERNATE_FORM    = '#'
    FLAG_CODE_ALIKE        = '_'
    FLAG_PAD_SPACE         = ' '
    FLAG_BRACKETS          = '['
    FLAG_ANGLE_BRACKETS    = '<'
    FLAG_SINGLE_QUOTES     = "'"
    FLAG_DOUBLE_QUOTES     = '"'
    FLAG_GRAVE_QUOTES      = '`'
    FLAG_C_COMMENT         = '*'

    ##
    # Create a SymbolFormatter that will format a symbol passed to its
    # format method (its instance menthod SymbolFormatter#format, not
    # the class method SymbolFormatter.format) according to
    # +format_str+. See also SymbolFormatter.compile.
    def initialize(format_str = DEFAULT_FORMAT_STR)
      @content = []
      
      pars_ctx = FmtStrParsingContext.new(format_str, @content)

      until pars_ctx.finished?
        if ordinary = OrdinaryChars.pick!(pars_ctx)
          pars_ctx.add_content(ordinary)
          break if pars_ctx.finished?
        end

        raise unless pars_ctx.pick_char! == '%' # XXX(assert)
        pars_ctx.cue!

        spec_class = nil
        char = pars_ctx.pick_char!
        until spec_class = SPECIFIER_CHAR_TO_CLASS[char] do
          char = pars_ctx.pick_char!
        end

        raise "unknown specifier at `#{pars_ctx.format_str[start..-1]}'" unless spec_class

        spec_obj = spec_class.new(pars_ctx)
        pars_ctx.add_content(spec_obj) unless spec_obj.is_a?(CondSectMark) or spec_obj.is_a?(ConvExtWrap) # TODO_R quick and dirty corner case handling
      end
    end

    def format(symbol)
      result = ''
      @content.each do |c|
        c.append(result, symbol)
      end
      result
    end # def format

    private

    class FmtStrParsingContext
      attr_reader :format_str
      attr_accessor :cursor
      attr_reader :cue_cursor
      attr_accessor :cur_content_holder
      def initialize(format_str, toplevel_content_holder)
        @format_str = format_str
        @cursor = 0
        @cue_cursor = nil
        @cur_content_holder = toplevel_content_holder
      end
      def finished?
        @cursor == @format_str.length
      end
      def remainder
        @format_str[@cursor..-1]
      end
      def pick_char!
        c = @format_str[@cursor]
        @cursor += 1
        c
      end
      def cue!
        @cue_cursor = @cursor
      end
      def cued_string
        @format_str[@cue_cursor...@cursor]
      end
      def add_content(spec_obj)
        @cur_content_holder << spec_obj
     end
    end

    class OrdinaryChars
      
      def initialize(string)
        @str = string
      end
      
      def self.pick!(pars_ctx)
        start = pars_ctx.cursor
        next_spec_idx = pars_ctx.format_str.index('%', start)
        if next_spec_idx
          str = pars_ctx.format_str[start...next_spec_idx]
          pars_ctx.cursor = next_spec_idx
        else
          str = pars_ctx.format_str[start..-1]
          next_spec_idx = pars_ctx.format_str.length
        end
        if str.empty?
          nil
        else
          self.new(pars_ctx.format_str[start...next_spec_idx])
        end
      end
      
      def append(destination, symbol)
        destination << @str
      end
      
    end # class OrdinaryChars

    
    module SpecifierWithFlagsMixin
      
      def flag?(*test_chars)
        test_chars.find {|tc| flags.include?(tc)}
      end
      
    end # module SpecifierWithFlagsMixin
    
    
    class Conversion

      include SpecifierWithFlagsMixin
      
      ##
      # +pars_ctx+ current FmtStrParsingContext
      # +conversion_specifier_str+ Part of the format string
      # specifying this conversion specifier, not including the
      # introducing '%' sign.
      def initialize(pars_ctx)
        @spec_str = pars_ctx.cued_string
      end

      def parse_spec_str
        raise "invalid conversion specifier: `#{@spec_str}'" unless @spec_str =~ /^(?<flags>[^.[:alnum:]]*)(?<min>\d+)?(.(?<max>\d+))?[[:alpha:]]$/        
        @flags     = Regexp.last_match[:flags].chars.to_a.to_set
        # XXX_F what gives better performance? @flags as string or as set?
        @min_width = Regexp.last_match[:min]
        @min_width = @min_width.to_i if @min_width
        @max_width = Regexp.last_match[:max]
        @max_width = @max_width.to_i if @max_width
      end
      private :parse_spec_str

      def flags
        parse_spec_str unless @flags
        @flags
      end

      def min_width
        parse_spec_str unless @min_width
        @min_width
      end
      
      def max_width
        parse_spec_str unless @max_width
        @max_width
      end

      def affect_conditional?
        flag?(FLAG_AFFECT_COND_SECT, FLAG_SELECT_COND_SECT)
      end

      ##
      # whether the information this conversion uses from the symbol
      # is trivial (wrt ? and ! flag)
      #
      # Child classes need to override this method to respond to ? and
      # ! flags properly.
      def trivial?(symbol)
        false
      end

      ##
      # whether the conversion is applicable to symbols like +symbol+
      #
      # Child classes which are not applicable to every symbol need to
      # override this method.
      def applicable?(symbol)
        true
      end

      def append(destination, symbol)
        destination << format(symbol)
      end
      
      def format(symbol)
        plain_string(symbol)
      end
      
    end # class Conversion
    
    
    class ConvSymIdentifier < Conversion
      def plain_string(symbol)
        symbol.identifier
      end
    end # class ConvSymIdentifier
    
    class ConvSymFamilyChar < Conversion
      def plain_string(symbol)
        symbol.class.family_character
      end
    end # class ConvSymFamilyChar
    
    class ConvSymFamilyName < Conversion
      def plain_string(symbol)
        symbol.class.family_name
      end
    end # class ConvSymFamilyName
    
    class ConvSymNativeType < Conversion
      def plain_string(symbol)
        raise "not yet implemented" # FIXME
      end
    end # class ConvSymNativeType
    
    class ConvSymImplicitType < Conversion
      def plain_string(symbol)
        raise "not yet implemented" # FIXME
      end
    end # class ConvSymImplicitType
    
    class ConvSymParamConversion < Conversion
      
      def trivial?(symbol)
        symbol.parameters.empty?
      end
      
      def applicable?(symbol)
        symbol.class.family == :function or
        (symbol.class.family == :macro and symbol.parameters)
      end

    end # class ConvSymParamConversion

    class ConvSymParamTypeList < ConvSymParamConversion
      def plain_string(symbol)
        if applicable?(symbol)
          raise "not yet implemented" # FIXME
        #parameters.map {|p| p.type_string}.join(', ')
        else
          ''
        end
      end
    end # class ConvSymParamTypeList
    
    class ConvSymParamCount < ConvSymParamConversion
      def plain_string(symbol)
        if applicable?(symbol)
          if flag?(FLAG_NO_TRIVIAL)
            if symbol.class.family == :function and
              flag?(FLAG_ALTERNATE_FORM)
              if symbol.parameters.empty? and
                not symbol.signatures.find {|s| s.is_void?} # XXX_W determine and use the "most significant" function signature
                ''
              else
                symbol.parameters.count.to_s
              end
            else
              if symbol.parameters.empty?
                ''
              else
                symbol.parameters.count.to_s
              end
            end
          else
            symbol.parameters.count.to_s
          end
        else
          ''
        end
      end
    end # class ConvSymParamCount
    
    class ConvSymParamNamedList < ConvSymParamConversion
      def plain_string(symbol)
        if symbol.respond_to? :parameters
          raise "not yet implemented" # FIXME
        #parameters.map {|p| p.type_string}.join(', ')
        else
          ''
        end
      end
    end # class ConvSymParamNamedList

    class ConditionConversion < Conversion
      def trivial?(symbol)
        symbol.existence_conditions.tautology?
      end
    end
    
    class ConvSymExistCond < ConditionConversion
      def plain_string(symbol)
        if flags.contain?(FLAG_CODE_ALIKE)
          symbol.existence_conditions.to_code(
            flags.contain?(FLAG_ALTERNATE_FORM)
          )
        else
          symbol.existence_conditions.to_s
        end
      end
    end # class ConvSymExistCond
    
    class ConvSymExistProb < ConditionConversion
      def plain_string(symbol)
        symbol.existence_probability.to_s
      end
    end # class ConvSymExistProb
    
    class ConvSpecialTabstop < Conversion

      def append(destination, symbol)
        if min_width and destination.length < min_width
          destination << ' ' * (min_width - destination.length)
        elsif max_width
          Rocc::Helpers::String.str_abbrev!(destination, max_width)
        end        
      end
      
    end # class ConvSpecialTabstop

    class CondSection
      
      attr_reader :parent
      
      def initialize(parent)
        @parent = parent
        @parts = [ CondSectPart.new ]
      end
      
      def add_part
        @parts << CondSectPart.new
      end
      
      def <<(arg)
        @parts.last << arg
      end

      def append(destination, symbol)
        active_part = find_active_part(symbol)
        active_part.append(destination, symbol) if active_part
      end
      
      def find_active_part(symbol)
        latest_candidate_part = nil
        active_part = @parts.find do |part|
          part.content.find do |spec|
            if spec.is_a?(Conversion) and spec.affect_conditional?
              latest_candidate_part = part
              spec.applicable?(symbol) and not spec.trivial?(symbol)
            else
              false
            end
          end
        end
        if active_part
          active_part
        elsif latest_candidate_part != @parts.last
          @parts.last
        else
          nil
        end
      end # def format
      
    end # class CondSection
    
    class CondSectPart
      
      attr_reader :content
      
      def initialize
        @content = []
      end

      def <<(arg)
        @content << arg
      end

      def append(destination, symbol)
        @content.each {|c| c.append(destination, symbol)}
      end
      
    end # class Conditional

    class CondSectMark; end

    class CondSectStart < CondSectMark
      def initialize(pars_ctx)
        new_sect = CondSection.new(pars_ctx.cur_content_holder)
        pars_ctx.cur_content_holder << new_sect
        pars_ctx.cur_content_holder = new_sect
      end
    end
    
    class CondSectDivider < CondSectMark
      def initialize(pars_ctx)
        pars_ctx.cur_content_holder.add_part
      end
    end
    
    class CondSectEnd < CondSectMark
      def initialize(pars_ctx)
        pars_ctx.cur_content_holder = pars_ctx.cur_content_holder.parent
      end
    end
    
    class ConvExtWrap
      
      include SpecifierWithFlagsMixin
      
      attr_reader :flags

      def initialize(pars_ctx)
        @flags = pars_ctx.cued_string.chop
        @pars_ctx = pars_ctx # TODO_R quick and dirty, smells !!
        @parent = pars_ctx.cur_content_holder
        @parent << self
        pars_ctx.cur_content_holder = self
        @target_spec = nil
      end
      
      def <<(arg)
        raise if @target_spec # XXX(assert)
        @target_spec = arg
        @pars_ctx.cur_content_holder = @parent
        @pars_ctx = nil
        @parent = nil
      end

      def append(destination, symbol)
        if flag?(FLAG_APPLICABLE) and
          not @target_spec.applicable?(symbol)
          @target_spec.append(destination, symbol)
        elsif flag?(FLAG_NO_TRIVIAL) and
          (not @target_spec.applicable?(symbol) or
           @target_spec.trivial?(symbol))
          @target_spec.append(destination, symbol)
        else
          destination << '('
          @target_spec.append(destination, symbol)
          destination << ')'
        end
      end # def append

    end # class ConvExtWrap

    class SpecialCharacter; end

    class SpecialCharPercent < SpecialCharacter
      def append(destination, symbol)
        destination << '%'
      end
    end
    
    class SpecialCharNewline < SpecialCharacter
      def append(destination, symbol)
        destination <<  "\n"
      end
    end
    
    class SpecialCharTab < SpecialCharacter
      def append(destination, symbol)
        destination << "\t"
      end
    end
    
    #PICKING_CLASSES = [
    #  SpecialCharacterSpecifier,
    #  ConditionalSection,
    #  ConversionSpecifier,
    #  ConversionExtension
    #]

    SPECIFIER_CHAR_TO_CLASS = {
      'i' => ConvSymIdentifier,
      'f' => ConvSymFamilyChar,
      'F' => ConvSymFamilyName,
      'y' => ConvSymNativeType,
      'Y' => ConvSymImplicitType,
      'p' => ConvSymParamTypeList,
      'P' => ConvSymParamCount,
      'q' => ConvSymParamNamedList,
      'c' => ConvSymExistCond,
      'C' => ConvSymExistProb,
      'T' => ConvSpecialTabstop,
      '(' => ConvExtWrap,
      '{' => CondSectStart,
      ':' => CondSectDivider,
      '}' => CondSectEnd,
      '%' => SpecialCharPercent,
      'n' => SpecialCharNewline,
      't' => SpecialCharTab,
    }

  end # class SymbolFormatter

end # module Rocc::Ui
