# -*- coding: utf-8 -*-

require_relative 'CodeObject'

require_relative 'Lines'

class CoFile < CodeObject
#  attr_reader :text, :lines

  def initialize(origin, rel_path, lines = nil)
    @rel_path = rel_path
    if File.exists?(rel_path)
      @valid = true
    end
    @abs_path = @rel_path # fixme

    @lines = lines
  end

  def get_location
    @abs_path
  end

  def valid?
    @valid
  end
  alias exists? valid?

  def to_s
    self.class.to_s + "[" + @rel_path + "]"
  end

  def lines
    unless @lines
      raise "Cannot read #{to_s}'." unless @valid
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
        @content.push CoPhysicLine.new(self, ln, idx)
      end
    end
    @content
  end

private

  def validate_origin(origin)
    # origin == nil is allowed  # fixme: in future, origin shall be commandline or another file
    if origin
      raise type_error origin unless origin.is_a? CoFile
    end
    origin
  end

end # class CoFile
