# -*- coding: utf-8 -*-

module Commands

class Command

  class << self
    attr_reader :description
  end

  @name = 'AbstractCommand'
  @description = 'undocumented'

  @@command_classes = {} # fixme(?): use `inherited' hook ?

  def self.command_classes
    @@command_classes
  end

  def self.register
    @@command_classes[@name] = self
  end
  
  def self.invoke(env, commandline)

    # ignore comments
    return if commandline =~ /\s*#/

    argv = commandline.split(/\s+/) # fixme: quotes, escapes

    cmd = argv.shift
    @@command_classes[cmd].call(env, argv)

  end # invoke

  def self.call(env, argv)
    options = {}
    option_parser(options).order!(argv)
    run(env, argv, options)
  end

  def self.run(env, argv, options)
    warn "Command `#{@name}' not yet implemented :("
  end

end # class Command

end # module Commands
