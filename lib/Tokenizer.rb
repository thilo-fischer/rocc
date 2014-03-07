# -*- coding: utf-8 -*-

raise "DEPRECATED"

require_relative '../CodeObjects/Tokens'

class Tokenizer

  def process(str)
    tokens = []
    str.strip!
    while not str.empty?
      if str.start_with? '/*'
        throw comment
      end
      if  str =~ CoTkWord.regexp_at_start or
          str =~ CoTkStringlitral.regexp_at_start or
          str =~ CoTkNumber.regexp_at_start or
          str =~ CoTk3Char.regexp_at_start or
          str =~ CoTk2Char.regexp_at_start or
          str =~ CoTk1Char.regexp_at_start
        tokens.push(Regexp.last_match)
        str = Regexp.last_match.post_match.lstrip
      else
        raise "Failed tokenizing `#{str}'. Abort."
      end
    end

    tokens
  end

end
