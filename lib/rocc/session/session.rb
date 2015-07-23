# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

##
# Things related to the currently running program instance.

module Rocc::Session

  require 'logger'

  require "rocc/session/options"

  class Session

    def initialize

      # parse command line arguments
      cmdlineparser = CommandLineParser.new
      cmdlineparser.parse

      # set up logging according to command line arguments
      setup_logging(cmdlineparser.logging_options)

      @options = OptionsRw.new

      # XXX set options from config files, config files may be specified as command line arguments
      set_config_dir(cmdlineparser.local_config_dir)
      # XXX read options from system/global/local config files
      # config_system.set_options(@options)
      # config_global.set_options(@options)
      # config_local.set_options(@options)

      # set options from command line (overriding )
      cmdlineparser.set_options(@options)

      @run = cmdlineparser.run
      @input_files = cmdlineparser.input_files
      
    end

    def options
      @options.readonly
    end

    def options_mutable
      @options
    end

    def run
      parse_input

      if @run == :interactive
        # Todo: When starting interactive session:
        #  <program>  Copyright (C) <year>  <name of author>
        #  This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
        #  This is free software, and you are welcome to redistribute it
        #  under certain conditions; type `show c' for details.
        raise "Not yet supported" # TODO
      else
        Commands::invoke(self, @run)
      end

    end # run
    
    private

    # XXX options: a string representing the desired log level.
    def setup_logging(options)
      $log = Logger.new(STDOUT)
      
      level = case options
              when "4", /^fatal/i   
                Logger::FATAL
              when "3", /^err/i     
                Logger::ERROR
              when "2", /^warn/i    
                Logger::WARN
              when "1", /^info/i    
                Logger::INFO
              when "0", /^de?bu?g/i 
                Logger::DEBUG
              when nil              
                Logger::WARN
              else
                nil
              end
      if level
        $log.level = level
      else
        $log.level = Logger::WARN
        $log.warn{"Invalid log level: `#{options[:verbosity]}'. Fall back to default log level."}
      end
      
      $log.debug{"Set log level to #{$log.level}."}
    end # setup_logging

    def parse_input

      base_directories = [ CeBaseDirectory.new(:working_dir, '.') ]
      
      translation_units = []

      @input_files.each do |f|
        raise "No such file or directory: `f'" unless File::exist?(f)
        case
        when File::file?(f)
          translation_units << CeTranslationUnit.new(ce_file(f))
        when File::directory?(f)
          # TODO find all source code files in f and its subdirectories and add as translation units to mdl
          raise "Not yet supported" # TODO
        when f == "-"
        mdl.add_translation_unit(:stdin) # FIXME seems wrong ... (?)
        else
          raise "Programming error :("
        end
      end
      
      # set up one default module
      # XXX set up according to linker options if such are supplied
      mdl = CeModule.new(translation_units, "a.out")
      @modules = [ mdl ]
             
      # files.map { |f| f.expand(ProcessingEnvironment.new($env.program)) }

    end # parse_input

    
    def ce_file(path, base_directories)
      # TODO do not create a new instance of CeFile if an according CeFile has been created previously.
      # XXX For all newly created FilesystemElements: check if two FilesystemElements (previously existing and newly created) refer to the same directory structure or file, use real_path to resolve symlinks.

      path = File::expand_path(path)

      # find the base_dir this file falls into
      base_dir = base_directories.find { |b| File::fnmatch(b.path + "**", path, File::FNM_PATHNAME) }

      # if not found, add according base_dir
      unless base_dir
        base_dir = CeBaseDirectory.new(:command_line_argument, File::dirname(path))
        # TODO if base_dir is parent directory of another dir already included in base_directories, remove that other base directory from base_directories and substitute its references to base_dir's according child dircetories
        base_directories << base_dir        
      end

      extname  = File::extname(path)
      basename = File::basename(path, extname)
      dirname  = File::dirname(path)

      raise "Programming error :(" unless dirname.start_with?(base_dir.path)
      dirname.slice!(base_dir.path)
      dirname.gsub!(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
      dirs = dirname.split(File::SEPARATOR)

      parent_dir = base_dir
      dirs.each do |d|
        ce_dir = CeDirectory.new(parent_dir, d)
        parent_dir.add_child(ce_dir)
        parent_dir = ce_dir
      end
      
      result = CeFile.new(  parent_dir, { :command_line_argument => [ path ] }, basename, extname )
    end # ce_file
    
  end # class Session

end # Rocc::Session

