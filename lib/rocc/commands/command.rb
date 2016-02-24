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

module Rocc::Commands

  #--
  # TODO move command management (registration, invokation, ...) from commands' base class Rocc::Commands::Command to appropriate management class or to module Rocc::Commands
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
      #warn "CMD #{cmd}"
      @@command_classes[cmd].call(env, argv)

    end # invoke

    def self.call(env, argv)
      options = {}
      option_parser(options).order!(argv)
      run(env, argv, options)
    end

    def self.run(env, argv, options)
      log.error{"Command `#{@name}' not yet implemented :("}
    end

  end # class Command

end # module Rocc::Commands
