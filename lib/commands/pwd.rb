# -*- coding: utf-8 -*-

class CommandPwd < Command

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

end # class Command


CommandPwd.register
