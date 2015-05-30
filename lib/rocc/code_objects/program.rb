# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

module Rocc::CodeObjects

  require 'rocc/code_objects/code_object'
  require 'rocc/code_objects/file'

  class CoProgram < CodeObject

    attr_reader :objects

    def initialize
      @objects = {}
    end

    def register(obj, key = obj.class)
      $env.logger.debug{ "new object in program: #{obj}" }
      objects_array(key) << obj
    end

    def objects_array(key)
      @objects[key] ||= []
    end

    def base_dir
      return nil if @objects[CoFile].empty?

      base_dir = @objects[CoFile].map do |f|
        #      File.dirname(f.abs_path).split('/')
        f.abs_path.split('/')[0..-2]
      end.inject do |base, new|
        #      for i in [0 .. base.length-1] do
        #        return base[0..i-1] if base[i] != new[i]
        #      end
        base.each_with_index do |dir, i|
          return base[0..i-1] if dir != new[i]
        end
        return base
      end
      
      File.join(base_dir)
    end # base_dir

    def to_s
      '^'
    end

#    def get_all
#      #@objects.keys.each do |k|
#      #end
#      @objects.values.flatten(1)
#    end
#
#    alias content get_all
#
#    def get_all_of_class(c)
#      raise unless c < CodeObject
#      @objects[c]
#    end
#
#    def get_all_of_kind(baseclass)
#      raise unless baseclass < CodeObject
#      result = []
#      @objects.each do |cls, objs| 
#        result += objs if cls < baseclass
#      end
#      result
#    end

    def list(io, options = {})
      if @objects.key?(:directory)
        io.puts string_representation(options)
      else
        dbg @objects.keys.inspect
        @objects.keys.each do |key|
          io.puts "#{key}:"
          @objects[key].each do |obj|
            io.puts "  #{obj.string_representation(options)}"
          end
        end
      end
    end # list

    private

    def validate_origin(origin)
      # Program is root node => origin == nil
      raise if origin != nil
      nil
    end

  end # class CoProgram

end # module Rocc::CodeObjects
