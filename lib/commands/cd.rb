# -*- coding: utf-8 -*-

class CommandCd < Command

  @name = 'cd'
  @description = 'Change current directory or object.'
  
  def self.option_parser(options)
    
    OptionParser.new do |opts|

      opts.banner = "Usage: #{@name} [options] [target]"
      
    end
    
  end # option_parser


  def self.run(env, args, options)
    
    if args.length == 0
      arg = "//"
    elsif args.length == 1
      arg = args[0]
    else
      # providing several arguments cds into all these sequentially (putting them into the oldpwd history)
      args.each { |a| run(env, [a], options) }
    end

    target = env.eval_path(arg)
    
    if target

      env.oldpwd << env.cursor

      case target
      when CodeObject
        env.obj_cursor = target
        env.cursor = env.obj_cursor
      when String
        Dir.chdir(target)
        env.cursor = Dir
      else
        raise
      end

    else

      warn "Cannot #{name} to `#{arg}': No such directory or object."

    end

  end # run

end # class Command


CommandCd.register
