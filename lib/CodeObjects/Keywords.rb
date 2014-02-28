# -*- coding: utf-8 -*-

class CoToken < CodeObject; end
class TknWord < CoToken; end

# forward declarations
class TknKeyword < TknWord; end
class TknKwCtrlflow < TknKeyword; end
class TknKwStdType < TknKeyword; end
class TknKwTypedef < TknKeyword; end
class TknKwQualifier < TknKeyword; end
class TknKwTypeVariant < TknKeyword; end
class TknKwMisc < TknKeyword; end


class TknKwCtrlflow < TknKeyword
  PICKING_REGEXP = Regexp.union %w(return if else for while do continue break switch case default goto)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKwStdType < TknKeyword
  PICKING_REGEXP = Regexp.union %w(void int char float double bool)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKwTypedef < TknKeyword
  PICKING_REGEXP = Regexp.union %w(typedef enum struct union)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKwQualifier < TknKeyword; end
class TknKwTypeQualifier < TknKwQualifier; end
class TknKwStorageQualifier < TknKwQualifier; end

class TknKwTypeQualifier < TknKwQualifier
  PICKING_REGEXP = Regexp.union %w(volatile const restrict)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKwStorageQualifier < TknKwQualifier
  PICKING_REGEXP = Regexp.union %w(static auto)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKwQualifier < TknKeyword
  SUBCLASSES = [ TknKwTypeQualifier, TknKwStorageQualifier ]
  PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c::PICKING_REGEXP})
end


class TknKwTypeVariant < TknKeyword
  PICKING_REGEXP = Regexp.union %w(signed unsigned short long)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKwMisc < TknKeyword
  PICKING_REGEXP = Regexp.union %w(inline sizeof _Complex _Imaginary)
  def self.create(origin, origin_offset, str)
    self.new(origin, origin_offset, str)
  end
end


class TknKeyword < TknWord
  SUBCLASSES = [ TknKwCtrlflow, TknKwStdType, TknKwTypedef, TknKwQualifier, TknKwTypeVariant, TknKwMisc ]
  PICKING_REGEXP = Regexp.union(SUBCLASSES.map{|c| c::PICKING_REGEXP})

  def self.create(origin, origin_offset, str)
    if tkn_class = SUBCLASSES.find {|cl| cl.test(str)}
      tkn_class.create(origin, origin_offset, str)
    else
      raise "Unknown preprocessor directive @#{origin}: `#{str}'"
    end
  end
end # TknKeyword

