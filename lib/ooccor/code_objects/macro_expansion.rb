# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

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
