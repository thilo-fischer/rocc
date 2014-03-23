# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::Commands

  require 'set'
  require 'ooccor/commands/command'

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
    require "ooccor/commands/#{c}"
  end

  erroneous = commands.to_set ^ Command.command_classes.keys.to_set
  unless erroneous.empty?
    raise ScriptError.new("Erroneous command implementations: #{erroneous.to_a.join(", ")}.")
  end

end # module Ooccor::Commands
