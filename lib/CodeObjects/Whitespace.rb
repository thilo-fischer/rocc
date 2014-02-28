# -*- coding: utf-8 -*-

class CoWhitespace < CodeObject
  @regexp = /\s+/

  def self.solve(str)
    str.gsub(@regexp, " ").gsub(/^\s+|\s+$/, "")
  end
end
