# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'optparse'

require 'rocc/session/options'
require 'rocc/session/logging'

##
# User Interface Implementations

module Rocc::Ui

  ##
  # Parses the command line arguments passed to the rocc program at invocation
  
  class CommandLineParser

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    attr_reader :input_files, :action, :include_dirs

    def initialize
      @options = {}
      @input_files = nil
      @action = :interactive
      @include_dirs = []
    end
    

    def parse
      
      option_parser = OptionParser.new do |opts|

        opts.banner = "Usage: #{File.basename $0} [options] [-c compiler [compiler-arguments]] [sourcefiles]"

        opts.on("-e 'command'",
                "--expression",
                "Run expression instead of starting an interactive sessios.") do |arg|
          @action = arg
        end

        opts.on("-c compiler",
                "--compiler",
                $supported_compilers.keys,
                "Parse compiler arguments according to the given compiler.",
                " (Currently supported: #{$supported_compilers.keys.map{|s| s.to_s}.join(', ')})",
                " Has to be the last rocc argument, all following arguments are regarded as arguments to the compiler.") do |arg|
          throw :compiler, $supported_compilers[arg].new
        end

        opts.on("--init",
                "Set up and fill the code analysis cache. Clear and rebuild if cache already exists.") do
          @options[:init] = true
        end

        
        opts.on("-F",
                "--on-the-fly",
                "Parse the code directly when processing it, do not use code analysis cache.") do
          @options[:on_the_fly] = true
        end

        opts.on("-v 'verbosity'",
                "--verbosity",
                "Set log level of rocc session.") do |arg|
          @options[:verbosity] = arg
        end

        opts.on("--change-detection 'method'",
                "Select method how to check if a file changed: mtime (default), sha1 or mtime+sha1.") do |arg|
          @options[:change_detection] = arg
        end

        opts.on("-I 'dir'",
                "Add dir to the list of directories to search for header files.") do |arg|
          @include_dirs << arg
        end

      end # OptionParser.new

      # parse all arguments until a --compiler argument

      compiler = catch :compiler do
        option_parser.order!
        nil # return nil from catch block if not catched
      end

      # handle Compiler arguments (if --compiler argument was given before)

      if compiler
        @options[:compiler] = compiler
        compiler.parse_argv
        @input_files = compiler.input_files
      else
        @input_files = ARGV
      end

    end # def parse
    

    def logging_options
      @options[:verbosity]
    end # logging_options
    
    
    def local_config_dir
      nil # TODO
    end # local_config_dir
    

    def set_options(optsobj)
      @options.each do |key, value|
        case key
        when :on_the_fly
          optsobj.enable(key)
        when :verbosity, :change_detection
          optsobj.set(key, value)
        else
          log.warn{"No option associated with command line argument of `#{key}'"}
        end
      end
    end # set_options

      
  end # class CommandLineParser

end # module Rocc::Ui
