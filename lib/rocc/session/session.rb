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

  require 'logger'

  require 'rocc/session/options'
  require 'rocc/session/application_context'
  require 'rocc/ui/cmdlineparser'
  require 'rocc/ui/interactive'
  require 'rocc/code_elements/file_represented/base_dir'
  require 'rocc/code_elements/file_represented/translation_unit'
  require 'rocc/code_elements/file_represented/module'
  require 'rocc/code_elements/file_represented/file'

##
# Things related to the currently running program instance.
#--
# XXX? use Singleton mixin? (TRPL 7.4.5)
module Rocc::Session

  class Session

    @@session = nil
    
    def self.current_session
      @@session
    end

    attr_reader :modules
    
    def initialize
      raise "There can only be one!" if @@session
      
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

      @action = cmdlineparser.action
      @input_files = cmdlineparser.input_files

      # Knowledge of current working directory will be necessary to be
      # able to reconstruct paths when using parsing results from a
      # previous rocc session (which might have had a different
      # working dir).
      @working_dir = Dir.pwd

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

      @application_context = ApplicationContext.new

      if @action == :interactive
        isession = Rocc::Ui::Interactive::Session.new(@application_context)
        isession.start
      else
        Rocc::Commands::Command::invoke(@application_context, @action)
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

      @input_files.each do |path|
        if path == "-"
          tu = CodeElements::FileRepresented::CeTranslationUnit.new(:stdin)
          translation_units << tu          
        else
          raise "No such file or directory: `#{path}'" unless File::exist?(path)
          if File::file?(path)
            f = ce_file(path, base_directories)
            tu = Rocc::CodeElements::FileRepresented::CeTranslationUnit.new(f)
            translation_units << tu
          elsif File::directory?(path)
            # TODO find all source code files in path and its
            # subdirectories and add as translation units
            raise "Not yet supported"
          else
            raise "Programming error :("
          end
        end
      end
      
      # set up one default module
      # TODO set up according to linker options if such are supplied
      mdl = Rocc::CodeElements::FileRepresented::CeModule.new(translation_units, "a.out")
      @modules = [ mdl ]
      @modules.each {|m| m.populate}

    end # parse_input


    def ce_file(path, base_directories)
      # TODO do not create a new instance of CeFile if a CeFile
      # instance for the same file has been created previously.
      
      # XXX For all newly created FilesystemElements: check if two
      # FilesystemElements (previously existing and newly created)
      # refer to the same directory structure or file, use real_path
      # to resolve symlinks.

      path = File::expand_path(path)

      # find the base_dir this file falls into
      base_dir = base_directories.find do |b|
        File::fnmatch(b.path_abs + "**", path, File::FNM_PATHNAME)
      end

      # if not found, add according base_dir
      unless base_dir
        base_dir = Rocc::CodeElements::FileRepresented::CeBaseDirectory.new(:command_line_argument, File::dirname(path))
        # TODO if base_dir is parent directory of another dir already
        # included in base_directories, remove that other base
        # directory from base_directories and substitute its
        # references to base_dir's according child dircetories
        base_directories << base_dir
      end

      direntryname = File::basename(path)
      dirname  = File::dirname(path)

      raise "Programming error :(" unless dirname.start_with?(base_dir.path_abs)
      dirname.slice!(base_dir.path_abs)
      dirname.gsub!(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
      dirs = dirname.split(File::SEPARATOR)

      parent_dir = dirs.inject(base_dir) do |parent_dir, dirname|
        child_dir = Rocc::CodeElements::FileRepresented::CeDirectory.new(parent_dir, dirname)
        parent_dir.add_child(child_dir)
        child_dir
      end
      
      result = Rocc::CodeElements::FileRepresented::CeFile.new(  parent_dir, { :command_line_argument => [ path ] }, direntryname )
    end # ce_file
    
  end # class Session

end # Rocc::Session

