# -*- coding: utf-8 -*-

module Commands

class CommandLs < Command

  @name = 'ls'
  @description = 'List objects.'
  
  def self.option_parser(options)
    
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
        options[:long] = true
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
      env.obj_cursor.content.each { |o| puts o.list }
    else
      args.each { |o| puts o.list }
    end

  end # run

end # class Command


CommandLs.register

end # module Commands
