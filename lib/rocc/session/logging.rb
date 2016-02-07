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

# XXX development aid
require 'rocc/session/devel_loglevels'

##
# Wrapper around ruby's Logger class allowing to activate different
# logging levels for different modules and classes.
module Rocc::Session

  module LogClientClassMixin

    def log(logtag = self)
      @logger ||= Hash.new
      #l = 
      @logger[logtag] ||= LogConfig.instance.get_logger(logtag)
      #warn "#{self}.log (class) => threshold: #{l.sev_threshold}"
      #l
    end

    def update_logger
      @logger = nil
      log
    end

  end

  module LogClientInstanceMixin

    def log(logtag = self.class)
      #l =
      self.class.log(logtag)
      #warn "#{self}.log (instance) => threshold: #{l.sev_threshold}"
      #l
    end

  end

  class LogConfig
    include Singleton

    # Set data members to nil to enforce invocation of setup method
    # before logger usage. (logger usage before setup will trigger
    # exceptions due to method invokations on nil.) XXX unclean ...
    def initialize
      @default_logger = nil
      @specific_loggers = nil
    end # initialize

    def setup(default_loglevel = DEFAULT_LOGLEVEL)
      @default_logger = create_logger
      @specific_loggers = {}
      
      set_default_threshold(default_loglevel)

      @default_logger.debug{"Default log level is #{@default_logger.sev_threshold}."}

      # XXX development aid
      if defined? SPECIFIC_LOGLEVELS
        SPECIFIC_LOGLEVELS.each_pair {|k,v| set_logtag_threshold(k,v)}
      end
      #warn "@specific_loggers=#{@specific_loggers}"
    end # setup

    def set_default_threshold(level)
      @default_logger.sev_threshold = level
    end # set_default_threshold

    def set_logtag_threshold(object, level)
      pattern = logtag_pattern_from_object(object)
      progname = pattern.to_s.sub(/\A\(\?-mix:\\A/, '').sub(/\\b\)\Z/, '')
      logger = @specific_loggers[pattern] ||= create_logger(level, progname)
      @default_logger.debug {"Set log level #{level} for #{pattern} (-> #{object})"}
    end # set_threshold

    ##
    # Returns the logger associated with the longest pattern matching
    # the logtag induced by +object+ if such exists, the default
    # logger otherwise.
    def get_logger(object)
      logtag = logtag_from_object(object)
      
      best_match = nil
      best_match_length = 0
      best_match_pattern = nil # XXX for debugging message only, remove
      @specific_loggers.each do |pattern, logger|
        if logtag =~ pattern
          match_length = Regexp.last_match.to_s.length
          if best_match.nil? or best_match_length < match_length
            best_match = logger
            best_match_length = match_length
            best_match_pattern = pattern
          end
        end
      end

      result =
      best_match || @default_logger
      warn "get_logger for #{object} -> logtag=#{logtag} -> best_match=#{best_match_pattern.inspect} -> logger: #{result.progname}, lvl#{result.level}"
      result
    end # get_logger

    ##
    # Tries to map different kinds of objects to a certain log level
    # as specified by the Logger::XYZ constants.  Returns the
    # appropriate Logger::XYZ constant or nil if no constant could be
    # associated with the given object.
    #--
    # XXX_R(private object_to_loglevel) make private?
    def self.object_to_loglevel(obj)
      case obj
      when nil
        DEFAULT_LOGLEVEL
      when Logger::FATAL.class
        nil unless [Logger::DEBUG..Logger::FATAL].include?(obj)
      when String
        case obj
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
        else
          nil
        end
      when Symbol
        object_to_loglevel(obj.to_s)
      else
        nil
      end
    end # object_to_loglevel


    private

    DATETIME_FORMAT = '%H:%M:%S.%L'
    FORMATTER = proc do |severity, datetime, progname, msg|
      "#{severity.to_s[0]} #{datetime.strftime(DATETIME_FORMAT)} > #{progname}: #{msg.gsub("\n", "\n\t")}\n"
    end
    DEFAULT_LOGLEVEL = Logger::INFO
    DEFAULT_PROGNAME = 'rocc'

    def create_logger(level = DEFAULT_LOGLEVEL, progname = DEFAULT_PROGNAME)
      logger = Logger.new(STDERR)
      logger.formatter = FORMATTER
      logger.progname = progname
      logger.sev_threshold = level
      logger
    end

    def logtag_from_object(object)
      case object
      when LogClientClassMixin
        object.name
      when LogClientInstanceMixin
        object.class.name
      when Symbol
        object.to_s
      when String
        object
      else
        raise "invalid argument: #{object.inspect}"
      end
    end # def logtag_from_object

    def logtag_pattern_from_object(object)
      case object
      when LogClientClassMixin, LogClientInstanceMixin, Symbol, String
        Regexp.new("\\A#{Regexp.escape(object)}\\b")
      when Regexp
        object
      else
        raise "invalid argument: #{object.inspect}"
      end
    end # def logtag_from_object

  end # class RoccLogger

end # Rocc::Session
