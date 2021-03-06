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

module Rocc::Commands

  require 'set'
  require 'rocc/commands/command'

  commands = %w[
    help
    ls
    cd
    pwd
  ]

  # Todo:
  # tree
  # pp
  # mv
  # rm
  # sh

  commands.each do |c|
    require "rocc/commands/#{c}"
  end

  erroneous = commands.to_set ^ Command.command_classes.keys.to_set
  unless erroneous.empty?
    raise ScriptError.new("Erroneous command implementations: #{erroneous.to_a.join(", ")}.")
  end

end # module Rocc::Commands
