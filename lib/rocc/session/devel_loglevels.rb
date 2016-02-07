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
  SPECIFIC_LOGLEVELS = {
    #"Rocc::CodeElements::CharRepresented::CharObjectPicker" => 1,
    #"Rocc::CodeElements::CharRepresented::Tokens" => 0,
    #"Rocc::CodeElements::CharRepresented::" => 0,
    #/Rocc::CodeElements::CharRepresented::.*Comment/ => 0,
    "Rocc::CodeElements" => 1,
    "Rocc::Contexts" => 0,
    #/pursue/ => 0,
    "tkn_pursue" => 1,
  }

end
