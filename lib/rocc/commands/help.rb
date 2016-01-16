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

module Rocc::Commands

  class Help < Command

    @name = 'help'
    @description = 'List available commands, print help of specific commands.'

    def self.option_parser(options)
      
      OptionParser.new do |opts|      

        opts.banner = "Usage: #{@name} [command]"
        
      end
      
    end # option_parser


    def self.run(env, args, options)
      
      if args.empty? then
        Command.command_classes.each do |name, cmd_class|
          puts "#{name}\t- #{cmd_class.description}"
        end
      else
        args.each do |cmd|
          if Command.command_classes.key?(cmd)
            puts Command.command_classes[cmd].option_parser(options).help
          else
            puts "Unknown command: `#{cmd}'"
          end
        end
      end

    end # run

  end # class Help


  Help.register

end # module Rocc::Commands
