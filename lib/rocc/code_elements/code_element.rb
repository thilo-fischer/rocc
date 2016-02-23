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

require 'rocc/session/logging'

module Rocc::CodeElements

  ##
  # Base class for all artifacts rocc may identify when analysing source code.
  # All child classes shall get the prefix `Ce' for *C*ode*E*lement to prevent name clashes with Ruby keywords or (std) lib identifiers, e.g. CoFile < CodeElement.
  #--
  # XXX consider making CodeElement a module instead of a class and use it as mixin
  class CodeElement

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    ##
    # Each CodeElement shall have an origin which refers to the object
    # it is a part of. The origin can be of various kind depending on
    # the class derived from the CodeElement class. The origin of a
    # CodeElement A shall be the CodeElement where you would expect to
    # go when doing a +cd ..+, and where you would expect to find A
    # listed when doing a +ls -A+. FIXME This is not yet consistently
    # implemented in all CodeElements. Force through!
    #
    # Classes deriving from CodeElement shall use the term +origin+ in
    # their source code to mark the object they use as their
    # origin. They may define aliases to give a more meaningful name
    # to it. For example:
    # - The origin of a file is the directory the file is located in.
    #   It defines an alias +parent_dir+ for +origin+.
    # - The origin of a variable is either the enclosing block it is
    #   defined in or the translation unit if not enclosed by a block.
    #   It defines an alias +scope+ for +origin+.
    def initialize(origin)
      @origin = origin
    end

    ##
    # The CodeElement this element originates form, i.e. the element
    # at the previous level in the full path.
    attr_reader :origin

    ##
    # The object that represents the reason for this code element to
    # be part of the program.  For most code elements, this is the
    # origin, but e.g. for files this can be the command line argument
    # that directed to this file or the file from which it was
    # included or similar.
    alias adducer origin

    alias original_to_s to_s
    alias original_inspect inspect

    def to_s
      name_dbg
    end

    def to_s_shortclassname
      original_to_s.slice(/:[^:]+:[^:]+$/).sub(':', '#<')
    end
    private :to_s_shortclassname

    ##
    # Overridden +inspect+ as ruby's original inspect results in several hundred characters for a usual CodeElement.
    def inspect
      orig_to_s = original_to_s
      raise unless orig_to_s[-1] == '>'
      orig_to_s.chop + " " + path_dbg + '>'
    end

    #def class_basename
    #  self.class.to_s.split('::').last
    #end

    ##
    # String to represent this element in rocc debugging and internal
    # error messages. Shall include an indication of the element's
    # nature (i.e. the CodeElement's subclass the element is an
    # instance of).
    def name_dbg
      s = to_s_shortclassname
      n = name
      if (n == s)
        s
      else
        "#{s.chop} - #{n}>"
      end
    end

    ##
    # String to represent this element in messages from rocc.  May be
    # just the identifier associated with the element, the element's
    # nature shall become clear from the context where +name+ is being
    # used.
    def name
      to_s_shortclassname
    end

    ##
    # Character(s) to use to separate this element from its origin in
    # path information.
    def path_separator
      " > "
    end
    private :path_separator
    
    ##
    # Path to file and to scope in file where this element
    # resides. Might skip some elements from the origin-chain which
    # are usually not of interest for rocc applications.
    #--
    # XXX_R code redundancy to path_full and path_dbg
    def path
      case @origin
      when nil
        name
      when CodeElement
        @origin.path + path_separator + name
      when Array
        '[' + @origin.map {|o| o.path}.join(', ') + ']' + path_separator + name
      end
    end

    ##
    # Path to file and to scope in file where this element resides
    # listing all elements actually in the origin-chain.
    #--
    # XXX_R code redundancy to path and path_dbg
    def path_full
      case @origin
      when nil
        name
      when CodeElement
        @origin.path_full + path_separator + name
      when Array
        '[' + @origin.map {|o| o.path_full}.join(', ') + ']' + path_separator + name
      end
    end

    ##
    # Path to the element to be used in rocc debugging and internal
    # error messages.
    #--
    # XXX_R code redundancy to path and path_full
    def path_dbg
      case @origin
      when nil
        name_dbg
      when CodeElement
        @origin.path_dbg + path_separator + name
      when Array
        '[' + @origin.map {|o| o.path_dbg}.join(', ') + ']' + path_separator + name
      end
    end

    ##
    # Like path, but discard any file information, i.e. start the path
    # only inside the translation unit.
    #
    # XXX? Question of best practise in Ruby code: Provide dummy
    # implementation at parent class (possibly not working for various
    # child classes and possibly throwing an exception) and override
    # in subclasses or use duck typing and define in according child
    # classes only?
    def scope
      raise "Invalid operation for #{name_dbg} (or not yet implemented)."
    end

    ##
    # Like path, but discard scope information, i.e. only give file
    # path and line number.
    #
    # XXX? Question of best practise in Ruby code: Provide dummy
    # implementation at parent class (possibly not working for various
    # child classes and possibly throwing an exception) and override
    # in subclasses or use duck typing and define in according child
    # classes only?
    def location
      raise "Invalid operation for #{name_dbg} (or not yet implemented)."
    end

    ##
    # Find the origin's origin, or the origin's origin's origin, or
    # ... If +depth+ is a non-negative integer number, descend this
    # many steps, where a +descend_origin(1)+ is equivalent to +self+
    # and +descend_origin(1)+ is equivalent to +origin+. If +depth+ is
    # a +Class+ (that is a subclass of +CodeElement+), descend until
    # an origin is found that +is_a?+ +depth+.
    def descend_origin(depth = 1)
      warn "#{self}.decend_origin(#{depth})"
      case depth
      when Integer
        if depth == 0
          self
        elsif depth > 0
          @origin.descend_origin(depth - 1)
        else
          raise "Programmin error :("
        end
      when Class
        raise "Invalid argument: must be an instance of a class derived from CodeElement" unless depth < CodeElement
        if self.is_a? depth then
          self
        elsif @origin
          @origin.descend_origin(depth)
        else
          nil
        end
      else
        raise "Invalid argument"
      end
    end # origin

    ##
    # Process this code element and update the given context
    # accordingly. To be overridden by those subclasses that support
    # according operations.
    #
    # Returns the "duty" left to invoking method: returns nil if all
    # operations necessary to pursue the context according to the
    # current code element could be achieved by the method directly,
    # returns true or another use case specific value if further
    # operations are necessary. This way, a child class C of a class B
    # derived from CodeElement (i.e. +C < B < ... < CodeElement+)
    # chaining pursue (i.e. +C#pursue+ invokes +B#pursue+ using
    # +super+) can get feedback from B whether +B#pursue+ already
    # pursued the context accordingly or whether +C#pursue+ has still
    # to take some additional steps to finish the processing of the
    # code element.  TODO_R force through this convention for all
    # implementations of pursue. TODO_R? Use throw-catch instead of
    # return value?
    #
    # XXX? Question of best practise in Ruby code: Provide dummy
    # implementation at parent class (possibly not working for various
    # child classes and possibly throwing an exception) and override
    # in subclasses or use duck typing and define in according child
    # classes only?
    #
    # E.g. CeFile and CeLogicLine define +content+ and invoke this
    # implementation.
    def pursue(context)
      content.map {|c| c.pursue(context)}.find {|r| not r.nil?}
    end
    
#    def <=>(other)
#      if @origin == other.origin
#        if self.respond_to?(:origin_offset)
#          return self.origin_offset <=> other.origin_offset
#        else
#          return 0
#        end
#      else
#        return @origin <=> other.origin
#      end
#    end

    def existence_conditions
      #warn "XXX CodeElement#existence_conditions on #{name_dbg}/#{original_to_s} (#{self.class}) -> same conditions as #{adducer}"
      case adducer
      when CodeElement
        adducer.existence_conditions
      when Array
        @cached_conditions ||= Rocc::Semantic::CeConjunctiveCondition.new(adducer.map {|a| a.existence_conditions})
      else
        raise
      end
    end

  end # class CodeElement

end # module Rocc::CodeObjects
