# -*- coding: utf-8 -*-

# The term specification is used here to mean all declarations and definitions. `Specification' is the superclass for all classes representing function, variable, type and struct/enum/union declarations and definitions.

class Specification < CodeObject

  def self.parse(env)
    token = env.parsing[:current_token]
    env.parsing[:current_token] = token.successor

    case token
    when TknKwTypedef
      SpecType.parse(env)
    when TknWord
      SpecVarFunc.parse(env)
else
raise
    end
  end

  def expand(env)
    nil
  end

end
