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

##
# Things related to the currently running program instance.
#--
# XXX use Singleton mixin? (TRPL 7.4.5)
module Rocc::Session

  require 'logger'

  require 'rocc/session/options'
  require 'rocc/ui/cmdlineparser'
  require 'rocc/code_elements/file_represented/base_dir'
  require 'rocc/code_elements/file_represented/translation_unit'
  require 'rocc/code_elements/file_represented/module'
  require 'rocc/code_elements/file_represented/file'

  class Session

    def self.current_session
      @@session
    end

    def initialize

      # parse command line arguments
      cmdlineparser = Rocc::Ui::CommandLineParser.new
      cmdlineparser.parse

      # set up logging according to command line arguments
      setup_logging(cmdlineparser.logging_options)

      @options = OptionsRw.new

      # set options from config files, config files may be specified as command line arguments
      #set_config_dir(cmdlineparser.local_config_dir)
      # XXX read options from system/global/local config files
      #config_system.set_options(@options)
      #config_global.set_options(@options)
      #config_local.set_options(@options)

      # set options from command line (overriding )
      cmdlineparser.set_options(@options)

      @run = cmdlineparser.run
      @input_files = cmdlineparser.input_files

      @@session = self
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
        Rocc::Commands::Command::invoke(self, @run)
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

      base_directories = [ Rocc::CodeElements::FileRepresented::CeBaseDirectory.new(:working_dir, '.') ]
      
      translation_units = []

      @input_files.each do |f|
        raise "No such file or directory: `f'" unless File::exist?(f)
        case
        when File::file?(f)
          tu = Rocc::CodeElements::FileRepresented::CeTranslationUnit.new(ce_file(f, base_directories))
          tu.populate
          translation_units << tu
        when File::directory?(f)
          # TODO find all source code files in f and its subdirectories and add as translation units to mdl
          raise "Not yet supported" # TODO
        when f == "-"
        mtranslation_units << CodeElements::FileRepresented::CeTranslationUnit.new(:stdin)
        else
          raise "Programming error :("
        end
      end
      
      # set up one default module
      # XXX set up according to linker options if such are supplied
      mdl = Rocc::CodeElements::FileRepresented::CeModule.new(translation_units, "a.out")
      @modules = [ mdl ]
      
      @modules.each { |m| m.populate }

    end # parse_input

    
    def ce_file(path, base_directories)
      # TODO do not create a new instance of CeFile if an according CeFile has been created previously.
      # XXX For all newly created FilesystemElements: check if two FilesystemElements (previously existing and newly created) refer to the same directory structure or file, use real_path to resolve symlinks.

      path = File::expand_path(path)

      # find the base_dir this file falls into
      base_dir = base_directories.find { |b| File::fnmatch(b.path + "**", path, File::FNM_PATHNAME) }

      # if not found, add according base_dir
      unless base_dir
        base_dir = Rocc::CodeElements::FileRepresented::CeBaseDirectory.new(:command_line_argument, File::dirname(path))
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
        ce_dir = Rocc::CodeElements::FileRepresented::CeDirectory.new(parent_dir, d)
        parent_dir.add_child(ce_dir)
        parent_dir = ce_dir
      end
      
      result = Rocc::CodeElements::FileRepresented::CeFile.new(  parent_dir, { :command_line_argument => [ path ] }, basename, extname )
    end # ce_file
    
  end # class Session

end # Rocc::Session

