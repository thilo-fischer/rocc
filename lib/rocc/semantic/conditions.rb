# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisly the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

module Rocc::Semantic

  class Conditions

    # TODO this implementations leaves much room for improvements:
    # * Check equivalence of conditions => should notice that `#ifdef foo' and `#if defined(foo)' or `foo == 1' and `1 == foo' mean the same etc.
    # * Improve performance!

    attr_reader :dbg_name

    def initialize(*varargs)
      # create dbg_name in constructor and store as member (in
      # contrast to assemble dbg_name dynamically) to allow insight in
      # the order in which the subsets and conditionals have been
      # passed to the constructor
      @subsets = []
      @conditionals = []
      @dbg_name = "<"
      varargs.each do |arg|
        case (arg)
        when Conditions
          @subsets << arg
        when CoPpConditional
          @conditionals << arg
        else
          raise "invalid argument"
        end
        @dbg_name += "#{arg.dbg_name},"
      end
      @dbg_name.chop!
      @dbg_name += ">"
    end

    def all_conditionals
      collection = @conditionals
      @subsets.each {|s| collection += s.all_conditionals }
      collection
    end

    ##
    # Returns the conjunction of these and the other conditions.
    #
    # FIXME test for self or other empty, self < other, self < other, ...
    def +(other)
      Conditions.new(self, other)
    end

    #alias conjunction +
    
    ##
    # Returns all conditions implied by this object, but not by the
    # other.  Returns nil if all conditions of this object are implied
    # by the other, i.e. the other's conditions is a superset of
    # this' conditions.
    def -(other)
      if self == other
        return nil
      elsif @subsets.contain?(other)
        return Conditions.new(@subsets.xxxxx(other), @conditionals)
      else
        self_all_conditionals = all_conditionals
        other_all_conditionals = other.all_conditionals
        self_all_conditionals.each do |c|
          self_all_conditionals.removeXXX(c) if other_all_conditionals.contain?(c)
        end
      end
    end

    ##
    # Returns true if the conditions of this object imply all
    # conditions of the other, i.e. this object's conditions is a
    # superset of the other's.
    def >(other)
      self - other
    end

    ##
    # Returns true if the conditions of this object are all implied by
    # the conditions of the other, i.e. this object's conditions is a
    # subset of the other's.
    def <(other)
      other - self
    end

    def =(other)
      (not self < other) and (not self > other)
    end

    

  end # class Conditions

end # module Rocc::Semantic
