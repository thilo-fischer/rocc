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

module Rocc::CodeElements::CharRepresented

  class CeCoPpError < CeCoPpDirective
    @REGEXP = /^#\s*error\s+.*/  

    # TODO_W
    def pursue(compilation_context)
      super_duty = super
      return nil if super_duty.nil?

      # remove `#error' from @text
      @text.slice!(/#\s*error\s+/)
      raise "pp#error: `#{@text}'"
    end
    
  end # class CeCoPpError

  class CeCoPpPragma < CeCoPpDirective
    @REGEXP = /^#\s*pragma\s+.*/
    
    # XXX_W?
    def pursue(compilation_context)
      super_duty = super
      return nil if super_duty.nil?

      log.warn{"ignoring #{location}: `#{@text}' "}
    end
    
  end # class CeCoPpPragma

  class CeCoPpLine < CeCoPpDirective

    @REGEXP = /^#\s*line\s+/

    # TODO_W
    def pursue(compilation_context)
      super_duty = super
      return nil if super_duty.nil?

      raise "not yet supported"
    end # pursue_branch

    #def expand(env)
    #
    #  raise "invalid syntax" unless successor.is_a? TknNumber # fixme: provide appropriate exception
    #  @number = Integer(successor.text)
    #
    #  if successor.successor
    #    raise "invalid syntax" unless successor.is_a? TknStringLitral # fixme: provide appropriate exception
    #    @filename = successor.successor.text.dup
    #    @filename[ 0] = ""
    #    @filename[-1] = ""
    #  end
    #
    #  env.preprocessing[:line_directive] = self
    #
    #  env.preprocessing.freeze
    #  env.preprocessing = env.preprocessing.dup
    #
    #end # expand

  end # class CeCoPpLine

end # module Rocc::CodeElements::CharRepresented::Tokens
