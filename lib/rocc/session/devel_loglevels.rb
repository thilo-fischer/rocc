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

##
# Development aid. Specifies log levels to associate with certain
# modules and classes.

module Rocc::Session

  ##
  # Map from classes and modules that extend and include the LogClient
  # mixins to the according log levels to be used when logging from
  # those modules.
  # 
  # Log levels are given as plain numbers according to the Logger::XYZ
  # constants, i.e.
  #  4 => Logger::FATAL
  #  3 => Logger::ERROR
  #  2 => Logger::WARN
  #  1 => Logger::INFO
  #  0 => Logger::DEBUG
  #
  # The keys that map to the log levels shall be either +String+s or
  # +Regexp+s that will be matched to the logtags used when
  # logging. The logtag of the default logger of a class including the
  # LogClient mixins is its class' name.
  #
  # Will only have effect if file is +require+d from logging.rb and
  # the default loglevel is either debug or info (i.e. will be
  # disabled when default loglevel is configured to warning or above).
  #
  # LogConfig does not include the LogClient mixins, but may also be
  # assigned a loglevel. A Sting (i.e. "Rocc::Session::LogConfig")
  # must be used as key then, a Regexp pattern is not supported for
  # LogConfig.
  SPECIFIC_LOGLEVELS = {
    "Rocc::Session::LogConfig" => 2,
    "Rocc::Semantic::SymbolIndex" => 2,
    "Rocc::CodeElements::CharRepresented::CharObjectPicker" => 2,
    #"Rocc::CodeElements::CharRepresented::Tokens" => 0,
    #"Rocc::CodeElements::CharRepresented::" => 0,
    #/Rocc::CodeElements::CharRepresented::.*Comment/ => 0,
    "Rocc::CodeElements" => 1,
    "Rocc::Semantic" => 1,
    "Rocc::Contexts" => 0,
    #/pursue/ => 0,
    "tkn_pursue" => 2,
  }

end
