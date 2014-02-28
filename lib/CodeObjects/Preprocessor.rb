# -*- coding: utf-8 -*-

require_relative 'CodeObject'
require_relative 'Tokens'

# forward declarations
class TknPpDirective < CoToken; end
class TknPpConditional < TknPpDirective; end
class TknPpDefine < TknPpDirective; end
class TknPpUndef < TknPpDirective; end
class TknPpError < TknPpDirective; end
class TknPpPragma < TknPpDirective; end
class TknPpLine < TknPpDirective; end


class TknPpDirective < CoToken
  PICKING_REGEXP = /^#\s*\w+/
  SUBCLASSES = [ TknPpConditional, TknPpDefine, TknPpUndef, TknPpError, TknPpPragma, TknPpLine ]

  def self.create(origin, origin_offset, str)
    if tkn_class = SUBCLASSES.find {|cl| cl.test(str)}
      tkn_class.create(origin, origin_offset, str)
    else
      raise "Unknown preprocessor directive @#{origin}: `#{str}'"
    end
  end

  def process(env)
    env.context.push(self)
  end
end # class TknPpDirective


class TknPpDefine < TknPpDirective
  PICKING_REGEXP = /^#\s*define\s+/
end # class

class TknPpUndef < TknPpDirective
  PICKING_REGEXP = /^#\s*undef\s+/
end # class

class TknPpError < TknPpDirective
  PICKING_REGEXP = /^#\s*error\s+/  
end # class

class TknPpPragma < TknPpDirective
  PICKING_REGEXP = /^#\s*pragma\s+/  
end # class

class TknPpLine < TknPpDirective
  PICKING_REGEXP = /^#\s*line\s+/  
end # class

class TknPpConditional < TknPpDirective
  PICKING_REGEXP = /^#\s*(if(n?def)?|elif|else|endif)\s+/
  @stack = []

  def self.process(line, origin)
    case line
    when TknPpCondIf.PICKING_REGEXP
      @stack.push TknPpCondIf.new origin
    when TknPpCondElif.PICKING_REGEXP
      TknPpCondElif.new origin, @stack[-1]
    when TknPpCondElse.PICKING_REGEXP
      TknPpCondElse.new origin, @stack[-1]
    when TknPpCondEndif.PICKING_REGEXP
      TknPpCondEndif.new origin, @stack.pop
    else
      raise "Unknown preprocessor conditional directive @#{origin}: `#{line}'"
    end # case logic_line
  end


private

  def check_related_if(related_if)
    raise type_error related_if unless related_if.is_a? TknPpCondIf
    related_if
  end

end # class

class TknPpCondIf < TknPpConditional
  PICKING_REGEXP = /^#\s*if(n?def)?\s+/

  def initialize(origin)
    super(origin)
    @elif = []
    warn "PpIf   initialized : " + to_s + " => `" + text + "'"
  end

  def text
    @origin.text
  end

  def add_elif(obj)
    @elif.push obj
  end

  def set_else(obj)
    @else = obj
  end

  def set_endif(obj)
    @endif = obj
  end

end # class

class TknPpCondElif < TknPpConditional
  PICKING_REGEXP = /^#\s*elif\s+/

  def initialize(origin, related_if)
    super(origin)
    @related_if = check_related_if related_if
    @related_if.add_elif self
    warn "PpElif initialized : " + to_s + " => `" + text + "'"
  end

  def text
    @origin.text
  end

end # class

class TknPpCondElse < TknPpConditional
  PICKING_REGEXP = /^#\s*else\s+/

  def initialize(origin, related_if)
    super(origin)
    @related_if = check_related_if related_if
    @related_if.set_else self
    warn "PpElse initialized : " + to_s + " => `" + text + "'"
  end

  def text
    @origin.text
  end

end # class

class TknPpCondEndif < TknPpConditional
  PICKING_REGEXP = /^#\s*endif\s+/

  def initialize(origin, related_if)
    super(origin)
    @related_if = check_related_if related_if
    @related_if.set_endif self
  end

  def text
    @origin.text
  end

end # class

