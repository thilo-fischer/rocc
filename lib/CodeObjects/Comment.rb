# -*- coding: utf-8 -*-

class CoComment < CodeObject
  @regexp = /\/\*.*?\*\/|\/\/.*$/

  def self.solve(str)
    solve!(str.dup)
  end

  def self.solve!(str)
    str.gsub! @regexp, " " # fixme: keep number of characters => replace comment by according number of space characters
  end
end
