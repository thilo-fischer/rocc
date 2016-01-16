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

  class Ls < Command

    @name = 'ls'
    @description = 'List objects.'
    
    def self.option_parser(options)

      options[:format] = :short
      
      OptionParser.new do |opts|      

        opts.banner = "Usage: #{@name} [options] [object]..."
        
        opts.on("-t type",
                "--type",
                %w[file symbol identifier macro function variable type tag struct union enum label],
                "list only objects of a certain type") do |arg|
          if options.key?(:type) then
            options[:type] = [arg]
          else
            options[:type] << arg
          end
        end

        opts.on("--literal [type]",
                %w[string char integer float],
                "list literals of specific type") do |arg|
          if options.key?(:literal) then
            options[:literal] = [arg]
          else
            options[:literal] << arg
          end
        end

        opts.on("--comment [type]",
                %w[block line],
                "list comments") do |arg|
          if options.key?(:comment) then
            options[:comment] = [arg]
          else
            options[:comment] << arg
          end
        end

        opts.on("-f criteria",
                "--filter",
                "list only objects matching the given filter criteria.") do |arg|
          if options.key?(:filter) then
            options[:filter] = [arg]
          else
            options[:filter] << arg
          end
        end

        opts.on("-l",
                "--long",
                "long listing format") do |arg|
          options[:format] = :long
        end

        opts.on("-F",
                "--classify",
                "append indicator representing it's type to objects") do |arg|
          options[:one_per_line] = true
        end

        opts.on("-1",
                "--one-per-line",
                "list one object per line") do |arg|
          options[:one_per_line] = true
        end

      end
      
    end # option_parser


    def self.run(env, args, options)
      
      if env.cursor == Dir then
        puts `ls #{args.join(" ")}`
      elsif args.empty?
        dbg " *** #{env.obj_cursor.objects.inspect}"
        env.logger.debug { "Listing of `#{env.obj_cursor}'" }
        env.obj_cursor.list(STDOUT, options)
      else
        args.each { |o| o.list(STDOUT, options) }
      end

    end # run

  end # class Ls


  Ls.register

end # module Rocc::Commands
