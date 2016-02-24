# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

require 'singleton'

require 'rocc/session/logging'
require 'rocc/session/options'
require 'rocc/session/application_context'
require 'rocc/contexts/parsing_context' # XXX? make paring context a subcontext of application context?
require 'rocc/ui/cmdlineparser'
require 'rocc/ui/interactive'
require 'rocc/code_elements/file_represented/translation_unit'
require 'rocc/code_elements/file_represented/module'
require 'rocc/code_elements/file_represented/file'


##
# Things related to the currently running program instance.
module Rocc::Session

  class Session

    include Singleton

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    attr_reader :input_files, :include_dirs, :action, :working_dir, :options

    attr_reader :modules
    
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

      @action = cmdlineparser.action
      @include_dirs = cmdlineparser.include_dirs
      @input_files = cmdlineparser.input_files

      # Knowledge of current working directory will be necessary to be
      # able to reconstruct paths when using parsing results from a
      # previous rocc session (which might have had a different
      # working dir).
      @working_dir = Dir.pwd
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
        # TODO_R quick and dirty
        actions = @action.split(';')
        #warn "ACTIONS #{actions}"
        actions.each do |a|
          #warn "INVOKE #{a}"
          Rocc::Commands::Command::invoke(@application_context, a.strip)
        end
      end

    end # run

    private

    # +options+ string representing the desired log level.
    def setup_logging(arg)
      # TODO_R(private object_to_loglevel)? move to LogConfig?
      level = LogConfig.object_to_loglevel(arg)
      if level
        LogConfig.instance.setup(level)
      else
        LogConfig.instance.setup
        log.warn{"Invalid log level: `#{arg}'. Fall back to default log level `#{log.sev_threshold}'."}
      end
    end # setup_logging

    def parse_input

      pars_ctx = Rocc::Contexts::ParsingContext.new

      translation_units = []

      @input_files.each do |path|
        if path == "-"
          tu = CodeElements::FileRepresented::CeTranslationUnit.new(:stdin)
          translation_units << tu          
        else
          raise "No such file or directory: `#{path}'" unless File::exist?(path)
          if File::file?(path)
            file = pars_ctx.fs_elem_idx.announce_element(Rocc::CodeElements::FileRepresented::CeFile, path, :input_file)
            tu = Rocc::CodeElements::FileRepresented::CeTranslationUnit.new(file)
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
      @modules.each {|m| m.populate(pars_ctx)}

    end # parse_input

  end # class Session

end # Rocc::Session

