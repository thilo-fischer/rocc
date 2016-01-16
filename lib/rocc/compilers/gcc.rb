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

module Rocc::Compilers

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

end # module Rocc::Compilers
