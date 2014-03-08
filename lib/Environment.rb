# -*- coding: utf-8 -*-

dbg "#{__FILE__}"

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

  attr_reader :oldpwd

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

    @cursor = @obj_cursor

    @oldpwd = []

  end # initialize

  # smells a bit ...
  def cursor
    case @cursor
    when Dir
      dir_cursor
    when @obj_cursor
      @obj_cursor
    else
      raise
    end
  end

  def cursor=(value)
    @cursor = value
  end


  def eval_path(path)

    case path
    when ":"
      return @obj_cursor
    when "::"
      return @program
    when /^:[^:]/
      return env.obj_cursor.find(arg)
    when /^::/
      return env.program.find(arg)
    when /^\/\//
      path[0] = "@base_dir"
    when /^@\//
      path[0] = "@out_dir"
    when /^\//
      path
    when /^~\//
      path[0] = "ENV[:HOME]"
    else
      if @cursor == Dir then
        path
      else
        eval_path(":/" + path)
      end
    end

  end # eval_path

end
