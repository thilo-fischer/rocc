#!/usr/bin/ruby -w
#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'

require_relative '../lib/ooccor.rb'

options = {}
option_parser = OptionParser.new do |opts|

  opts.banner = "Usage: #{File.basename $0} [options] [-c compiler [compiler-arguments]] [sourcefiles]"


  opts.on("-e 'command'",
          "--expression",
          "Run expression instead of starting an interactive sessios.") do |arg|
    options[:expression] = arg
  end

  opts.on("-c compiler",
          "--compiler",
          $supported_compilers.keys,
          "Parse compiler arguments according to the given compiler.",
          " (Currently supported: #{$supported_compilers.keys.map{|s| s.to_s}.join(', ')})",
          " Has to be the last ooccor argument, all following arguments are regarded as arguments to the compiler.") do |arg|
    throw :compiler, $supported_compilers[arg].new
  end

end

$compiler = catch :compiler do
  option_parser.order!
end

if $compiler
  $compiler.parse_argv
end

# fixme: which is better, 'chomp' or 'chomp!' ?
#file = CoFile.new nil, "ARGF", $<.readlines.map(&:chomp)
file = CoFile.new nil, "ARGF", $<.readlines.map(&:chomp!)

program = file.process(ProcessingEnvironment.new)


if options[:expression] then
  
end
