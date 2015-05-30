# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

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
