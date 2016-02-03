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
require 'singleton'

##
# Wrapper around ruby's Logger class allowing to activate different
# logging levels for different modules and classes.
module Rocc::Session

  module LogClientClassMixin

    def log
      @logger ||= LogConfig.instance.get_logger(logtag)
    end

    def logtag
      @logtag || self.class.name
    end

    def logtag=(arg)
      @logtag = arg
      update_logger
    end
    
    def update_logger
      @logger = nil
      log
    end

  end

  module LogClientMixin

    def log
      self.class.log
    end

  end

  class LogConfig
    include Singleton

    def initialize
      @default_logger = create_logger
      @specific_loggers = {}
    end # initialize

    def set_default_threshold(level)
      @default_logger.sev_threshold = level
    end # set_default_threshold

    def set_threshold(object, level)
      logtag = logtag_from_object(object)
      @specific_loggers[logtag] = create_logger(level, logtag)
      @default_logger.info {"set log level #{level} for #{logtag} (-> #{object})"}
    end # set_threshold

    def get_logger(object)
      logtag = logtag_from_object(object)
      
      best_match = nil
      @specific_loggers.keys.each do |k|
        if logtag.starts_with?(k)
          if best_match.nil? or best_match.length < k.length
            best_match = k
          end
        end
      end

      if best_match
        @secific_loggers[best_match]
      else
        @default_logger
      end
    end # get_logger


    private

    DATETIME_FORMAT = '%H:%M:%S.%L'
    FORMATTER = proc do |severity, datetime, progname, msg|
      "#{severity.to_s[0]} #{datetime.strftime(DATETIME_FORMAT)} > #{progname}: #{msg}\n"
    end
    DEFAULT_LOGLEVEL = Logger::INFO
    DEFAULT_PROGNAME = 'rocc'

    def create_logger(level = DEFAULT_LOGLEVEL, progname = DEFAULT_PROGNAME)
      logger = Logger.new(STDOUT)
      logger.formatter = FORMATTER
      logger.progname = progname
      logger.sev_threshold = level
      logger
    end

    def logtag_from_object(object)
      case object
      when Class
        raise unless object.include?(LogClientMixin)
        object.name
      when LogClientMixin
        object.class.name
      when Symbol
        object.to_s
      when String
        object
      else
        raise "invalid argument"
      end
    end # def logtag_from_object

  end # class RoccLogger

end # Rocc::Session

