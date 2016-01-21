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

module Rocc::CodeElements

  ##
  # Base class for all artifacts rocc may identify when analysing source code.
  # All child classes shall get the prefix `Ce' for *C*ode*E*lement to prevent name clashes with Ruby keywords or (std) lib identifiers, e.g. CoFile < CodeElement.
  #--
  # XXX consider making CodeElement a module instead of a class and use it as mixin
  class CodeElement

    def initialize(origin = nil)
      @origin = origin
      #announce
    end

#    # rrr
#    # register the object at its origin
#    def announce
#      @origin.register(self) if @origin
#    end
#
#    ##
#    # The code element this element originates form, i.e. the element
#    # at the previous level in the full path.
#    # rrr
    attr_reader :origin
##    def origin(depth = 1)
##      case depth
##      when Integer
##        if depth == 0
##          self
##        elsif depth > 0
##          @origin.origin(depth - 1)
##        else
##          raise
##        end
##      when Class
##        raise "Programmin error :(" unless depth < CodeElement
##        if self.is_a? depth then
##          self
##        elsif self.is_a? CoProgram
##          nil
##        else
##          @origin.origin(depth)
##        end
##      else
##        raise
##      end
##    end # origin

    ##
    # The object that represents the reason for this code element to
    # be part of the program.  For most code elements, this is the
    # origin, but e.g. for files this can be the command line argument
    # that directed to this file or the file from which it was
    # included or similar.
    alias adducer origin

    ##
    # string to represent this element in rocc debugging and internal error messages
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
    # string to represent this element in messages from rocc
    def name
      self.class.to_s.split('::').last
    end

    ##
    # character(s) to use to separate this element from its origin in path information
    def path_separator
      " > "
    end
    
    ##
    # path to file and to scope in file in which the element is defined
    def path
      if @origin
        @origin.path + path_separator + name
      else
        name
      end
    end

    ##
    # path to file and to scope in file in which the element is defined
    # listing all elements actually in the origin-chain
    def path_full
      if @origin
        @origin.path_full + path_separator + name
      else
        name
      end
    end

    ##
    # path to the element to be used in rocc debugging and internal error messages
    def path_dbg
      if @origin
        @origin.path_dbg + path_separator + name_dbg
      else
        name_dbg
      end
    end

    alias to_s path_dbg

    ##
    # like path, but discard any file information, i.e. start the path only
    # inside the translation unit
    alias scope path

    ##
    # like path, but discard scope information, i.e. only give file path and line number
    alias location path

#    # rrr
#    def string_representation(options = {})
#      if options.key?(:format)
#        case options[:format]
#        when :short
#          name
#        when :long
#          path
#        when :code
#          text
#        else
#          raise
#        end
#      else
#        name
#      end
#    end
#
#    # rrr
#    def list(io, options = {})
#      io.puts string_representation(options)
#    end

    ##
    # process this code element and update the given context accordingly
    def pursue(context)
      content.map {|c| c.pursue(context) }
    end
    
#    # take in objects that originate from this object
#    # rrr
#    def register(obj, key = obj.class)
#      dbg self.to_s
#      @origin.register(obj, key)
#    end
#
#    # fixme
#    # rrr
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

    protected

#    @ORIGIN_CLASS = CodeElement
#    class << self
#      attr_reader :ORIGIN_CLASS
#    end
#
#    def type_error(object)
#      if object
#        TypeError.new("`#{object}' is of wrong type `#{object.class}'")
#      else
#        TypeError.new("Object of certain type expected, but got nil.")
#      end  
#    end

    private
    
#    def validate_origin(origin)
#      raise type_error(origin) unless origin.is_a?(self.class.ORIGIN_CLASS)
#      origin
#    end

  end # class CodeElement

end # module Rocc::CodeObjects
