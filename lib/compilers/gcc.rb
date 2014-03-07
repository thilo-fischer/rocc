# -*- coding: utf-8 -*-

class CompilerGcc < Compiler

  def initialize

    @include_paths = []
    
  end # initialize

  def parse_argv
    option_parser = OptionParser.new do |opts|
      
      opts.on("-I path",
              "Add include path.") do |arg|
        @include_paths << arg
      end
      
    end # option_parser

    1.times do
      begin
        option_parser.order!
      rescue OptionParser::InvalidOption
        warn "Ignoring unsupported compiler argument. (The one before `#{ARGV[0]}'.)" # fixme
        redo
      end
    end
    
  end # parse_argv

end # class CompilerGcc
