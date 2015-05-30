# -*- coding: utf-8 -*-

class CommandSh < Command

  @name = 'sh'
  @description = 'run shell command'
  
  def self.option_parser
    
    OptionParser.new do |opts|

      opts.banner = "Usage: #{@name} [options] [--] shell-command [arguments]..."
      
      opts.on("--[no-]directory-shortcuts",
              "whether to substitute rocc directory shortcuts (/, @, :),",
              "default is to not do any substitution (might change in future ...)") do |arg|
        options[:directory_shortcuts] = arg
        raise "not yet implemented"
      end

      opts.on("--[no-]verbatim",
              "don't do any ...",
              "(implies --no-directory-shortcuts)") do |arg|
        options[:verbatim] = arg
        throw ...
        raise "not yet implemented"
      end

    end
    
  end # option_parser


  def self.run(args, options)
    
    system(args)

  end # run

end # class Command


CommandLs.register
