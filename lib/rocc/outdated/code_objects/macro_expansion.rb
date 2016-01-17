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

class CoMacroExpansion < CodeObject

  attr_reader :macro

  def initialize(origin, macro)
    super(origin)
    @macro = macro
  end # initialize

  def expand(env)
    @macro.tokens.each do |t|
      t.fork__rename(self).expand(env)
    end
  end # expand

  def conditions
    CoPpConditions.merge_and(origin.conditions, macro.conditions)
  end

end # class CoMacroExpansion
