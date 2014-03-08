# -*- coding: utf-8 -*-

require_relative '../CodeObject'

# forward declarations
class CoToken               < CodeObject;     end
class TknWord               < CoToken;        end
class TknKeyword            < TknWord;        end
class TknKwCtrlflow         < TknKeyword;     end
class TknKwStdType          < TknKeyword;     end
class TknKwTypedef          < TknKeyword;     end
class TknKwTypeVariant      < TknKeyword;     end
class TknKwMisc             < TknKeyword;     end
class TknKwQualifier        < TknKeyword;     end
class TknKwTypeQualifier    < TknKwQualifier; end
class TknKwStorageQualifier < TknKwQualifier; end


class TknKwCtrlflow < TknKeyword
  @PICKING_REGEXP = Regexp.union %w(return if else for while do continue break switch case default goto)
end


class TknKwStdType < TknKeyword
  @PICKING_REGEXP = Regexp.union %w(void int char float double bool)
end


class TknKwTypedef < TknKeyword
  @PICKING_REGEXP = Regexp.union %w(typedef enum struct union)
end


class TknKwTypeQualifier < TknKwQualifier
  @PICKING_REGEXP = Regexp.union %w(volatile const restrict)
end


class TknKwStorageQualifier < TknKwQualifier
  @PICKING_REGEXP = Regexp.union %w(static auto)
end


class TknKwQualifier < TknKeyword

  SUBCLASSES = [ TknKwTypeQualifier, TknKwStorageQualifier ]
  @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

  def self.pick!(env)
    if self != TknKwQualifier
      # allow subclasses to call superclasses method implementation
      super
    else
      tkn = nil
      SUBCLASSES.find {|c| tkn = c.pick!(env)}
      tkn
    end
  end   

end


class TknKwTypeVariant < TknKeyword
  @PICKING_REGEXP = Regexp.union %w(signed unsigned short long)
end


class TknKwMisc < TknKeyword
  @PICKING_REGEXP = Regexp.union %w(inline sizeof _Complex _Imaginary)
end


class TknKeyword < TknWord
  SUBCLASSES = [ TknKwCtrlflow, TknKwStdType, TknKwTypedef, TknKwQualifier, TknKwTypeVariant, TknKwMisc ]
  @PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c.picking_regexp})

# todo: test which version of pick! works faster
# (adapt TknKwQualifier.pick! accordingly)

  def self.pick!(env)
    if self != TknKeyword
      # allow subclasses to call superclasses method implementation
      super
    else
      tkn = nil
      SUBCLASSES.find {|c| tkn = c.pick!(env)}
      tkn
    end
  end   

#  def self.pick!(env)
#    if str = self.pick_string(env) then
#      tkn = nil
#      if SUBCLASSES.find {|c| tkn = c.pick!(env)} then
#        tkn
#      else
#        raise StandardError, "Error processing keyword, not accepted by subclasses @#{origin.list}: `#{str}'"
#      end
#    end
#  end   

end # TknKeyword


