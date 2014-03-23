# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::Commands

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

end # module Ooccor::Commands
