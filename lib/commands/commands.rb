# -*- coding: utf-8 -*-

require 'set'

require_relative 'Command'

commands = %w[
help
ls
cd
pwd
]

# todo:
# tree
# pp
# mv
# rm
# sh

commands.each do |c|
  require_relative c
end

erroneous = commands.to_set ^ Command.command_classes.keys.to_set
unless erroneous.empty?
  raise ScriptError.new("Erroneous command implementations: #{erroneous.to_a.join(", ")}.")
end
