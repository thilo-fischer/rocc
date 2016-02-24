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

  class Cd < Command

    @name = 'cd'
    @description = 'Change current code element (or directory).'
    
    def self.option_parser(options)
      
      OptionParser.new do |opts|

        opts.banner = "Usage: #{@name} [options] [target]"
        
      end
      
    end # option_parser


    def self.run(applctx, args, options)
      
      if args.length == 0
        # cd with no arguments cds into the highest level of the
        # current module (or into the module's translation unit if
        # module has only one translation unit)
        arg = "//"
      elsif args.length == 1
        arg = args.first
      else
        # providing several arguments cds into all these sequentially
        # (putting them into the cursor history)
        #
        # XXX sensible?
        args.each {|a| run(applctx, [a], options)}
      end

      applctx.cursor_cd(arg)

    end # run

  end # class Cd

  Cd.register

end # module Rocc::Commands
