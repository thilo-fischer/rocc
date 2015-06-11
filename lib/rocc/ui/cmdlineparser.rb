# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

##
# User Interface Implementations

module Rocc::Ui

  require 'optparse'

  require 'rocc/session/options'

  ##
  # Parses the command line arguments passed to the rocc program at invocation
  
  class CommandLineParser

    attr_reader :input_files, :run

    def initialize
      @options = {}
      @input_files = nil
      @run = :interactive
    end
    

    def parse
      
      option_parser = OptionParser.new do |opts|

        opts.banner = "Usage: #{File.basename $0} [options] [-c compiler [compiler-arguments]] [sourcefiles]"

        opts.on("-e 'command'",
                "--expression",
                "Run expression instead of starting an interactive sessios.") do |arg|
          @run = arg
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
          $log.warn{"No option associated with command line argument of `#{key}'"}
      end
    end # set_options

      
  end # class CommandLineParser

end # module Rocc::Ui
