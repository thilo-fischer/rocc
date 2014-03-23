# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects

  require 'ooccor/code_objects/code_object'
  require 'ooccor/code_objects/lines'

# forward declarations
class CoProgram < CodeObject; end

class CoFile < CodeObject
  attr_reader :abs_path

  def initialize(origin, path, lines = nil)
    @origin = origin
    @abs_path = File.expand_path(path)
    @lines = lines
    @content = nil
  end

  def valid?
    File.exists?(@abs_path)
  end
  alias exists? valid?

  def path
    p = @abs_path.dup
    p.sub!(/^#{Dir.getwd}/, ".")
    p.sub!(/^#{$env.base_dir}/, "/") if $env.base_dir
    p
  end

  def to_s
    self.class.to_s + ":" + path
  end

  def list(format = :short)
    case format
    when :short
      File.basename(@abs_path)
    when :explicit
      to_s
    else
      path
    end
  end

  def lines
    unless @lines
      raise "Cannot read `#{to_s}'." unless valid?
      File.open(@abs_path, "r") do |file|
        @lines = file.readlines.map(&:chomp!)
      end
    end
    @lines
  end # lines

  def content
    unless @content
      @content = []
      lines.each_with_index do |ln, idx|
        @content << CoPhysicLine.new(self, ln, idx)
      end
    end
    @content
  end

  def expand(env)
    super
    env.end_of_file
  end

protected

  @ORIGIN_CLASS = CoProgram

end # class CoFile

end # module Ooccor::CodeObjects
