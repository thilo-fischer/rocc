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

  class Pwd < Command

    @name = 'pwd'
    @description = 'Print current directory and object.'
    
    def self.option_parser(options)
      
      OptionParser.new do |opts|

        opts.banner = "Usage: #{@name} [options]"
        
      end
      
    end # option_parser


    def self.pwd(env)
      if env.cursor == Dir then
        str = "#{env.dir_cursor} / #{env.obj_cursor.list}"
      else
        str = "#{env.obj_cursor.list} / #{env.dir_cursor}"
      end
      str += " > #{env.out_dir}" if env.out_dir != "."
    end


    def self.run(env, args, options)
      
      puts pwd(env)

    end # run

  end # class Pwd


  Pwd.register

end # module Rocc::Commands
