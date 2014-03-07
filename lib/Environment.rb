# -*- coding: utf-8 -*-

class Environment

  attr_reader :program

  # Current directory in file system. Can be changed using `cd'. Shortcut: `.'
  def dir_cursor
    dir = File.expand_path(Dir.getwd)
#    if dir.starts_with?(@base_dir)
    dir.sub!(/^@base_dir/, "/")
  end

  attr_reader :obj_cursor   # Currently selected CodeObject. Can be changed using `cd'. Shortcut: `:'
  attr_reader :base_dir     # Root directory of the source tree. Shortcut: `/' (=> path starts with `//')
  attr_reader :out_dir      # By default, when output is written to a file, relative filenames will be used relative to dir_cursor. out_dir can be set or changed using `cd --output-dir' to make relative filenames being used relative to this directory. [This does however _not_ apply to relative filenames that start with `./', these are always relative to dir_cursor (as `.' is the shortcut for dir_cursor). Use shortcut `@' instead of `.' in those cases where you have to refer the 'current' directory.] Shortcut: `@'

  
  def initialize(options, compiler)

    @options  = options
    @compiler = compiler

    @program = CoProgram.new
    @obj_cursor = @program
    if options[:basedir] then
      @base_dir = File.expand_path(options[:basedir])
    else
      @base_dir = nil
    end
    @out_dir = "."

  end

end
