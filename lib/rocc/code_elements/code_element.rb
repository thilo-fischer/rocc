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

    ##
    # String to represent this element in rocc debugging and internal
    # error messages. Shall include an indication of the element's
    # nature (i.e. the CodeElement's subclass the element is an
    # instance of).
    def name_dbg
      class_s = self.class.to_s.split('::').last
      disp = name
      if (class_s == name)
        name
      else
        class_s + "(" + name + ")"
      end
    end

    ##
    # String to represent this element in messages from rocc.  May be
    # just the identifier associated with the element, the element's
    # nature shall become clear from the context where +name+ is being
    # used.
    def name
      self.class.to_s.split('::').last
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
    def path
      if @origin
        @origin.path + path_separator + name
      else
        name
      end
    end

    ##
    # Path to file and to scope in file where this element resides
    # listing all elements actually in the origin-chain.
    def path_full
      if @origin
        @origin.path_full + path_separator + name
      else
        name
      end
    end

    ##
    # Path to the element to be used in rocc debugging and internal
    # error messages.
    def path_dbg
      if @origin
        origin_path_dbg = case @origin
                          when Array
                            '[' + @origin.map {|o| o.path_dbg}.join(', ') + ']'
                          else
                            @origin.path_dbg
                          end
        origin_path_dbg + path_separator + name_dbg
      else
        name_dbg
      end
    end

    alias original_to_s to_s
    alias to_s name_dbg
    alias original_inspect inspect

    ##
    # Overridden +inspect+ as ruby's original inspect results in several hundred characters for a usual CodeElement.
    def inspect
      orig_to_s = original_to_s
      raise unless orig_to_s[-1] == '>'
      orig_to_s.chop + " " + path_dbg + '>'
    end

    ##
    # Like path, but discard any file information, i.e. start the path only
    # inside the translation unit.
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
        raise "Programmin error :(" unless depth < CodeElement
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
    # XXX? Question of best practise in Ruby code: Provide dummy
    # implementation at parent class (possibly not working for various
    # child classes and possibly throwing an exception) and override
    # in subclasses or use duck typing and define in according child
    # classes only?
    #
    # E.g. CeFile and CeLogicLine define +content+ and invoke this
    # implementation.
    def pursue(context)
      content.map {|c| c.pursue(context)}
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

    def conditions
      case adducer
      when CodeElement
        adducer.conditions
      when Array
        @cached_conditions ||= Rocc::Semantic::CeConjunctiveCondition.new(adducer.map {|a| a.conditions})
      else
        raise
      end
    end

  end # class CodeElement

end # module Rocc::CodeObjects
