# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::Compilers

  class Gcc < Compiler

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

  end # class Gcc

end # module Ooccor::Compilers
