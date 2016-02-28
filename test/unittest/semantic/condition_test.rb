require 'test_helper'

require 'rocc/semantic/condition'

class CeConditionTest < Test::Unit::TestCase

  include Rocc::Semantic

  def setup
  end

  def teardown
  end

  def test__unconditional__code__true
    c = CeUnconditionalCondition.instance
    assert_equal('true', c.to_code)
  end

  def test__atomic__code__literal
    c = CeAtomicCondition.new('A')
    assert_equal('A', c.to_code)
  end

  def test__negation_of_atomic__code__exclamation_mark
    a = CeAtomicCondition.new('A')
    c = CeNegationCondition.new(a)
    assert_equal('!(A)', c.to_code)
  end

  def test__conjunction__code__ampersands
    a = CeAtomicCondition.new('A')
    b = CeAtomicCondition.new('B')
    c = CeConjunctiveCondition.new([a, b])
    assert_equal('(A) && (B)', c.to_code)
  end

  def test__conjunction__empty__exception
    assert_raise(ArgumentError) do
      c = CeConjunctiveCondition.new([])
    end
  end

  def test__conjunction__single__exception
    a = CeAtomicCondition.new('A')
    assert_raise(ArgumentError) do
      c = CeConjunctiveCondition.new([a])
    end
  end

  def test__conjunction__single_twice__exception
    a = CeAtomicCondition.new('A')
    assert_raise(ArgumentError) do
      c = CeConjunctiveCondition.new([a, a])
    end
  end

  def test__conjunction__doublet__just_once
    a = CeAtomicCondition.new('A')
    b = CeAtomicCondition.new('B')
    c = CeConjunctiveCondition.new([a, a, b])
    e = CeConjunctiveCondition.new([a, b])
    assert_equal(e.to_code, c.to_code)
  end

  def test__conjuncted__code__ampersands
    a = CeAtomicCondition.new('A')
    b = CeAtomicCondition.new('B')
    c = a.conjunction(b)
    assert_equal('(A) && (B)', c.to_code)
  end

  def test__conjuncted__same__same
    a = CeAtomicCondition.new('A')
    c = a.conjunction(a)
    assert_equal(a, c)
  end

  def test__conjuncted__code__ampersands_and_flattened
    a = CeAtomicCondition.new('A')
    b = CeAtomicCondition.new('B')
    c = CeAtomicCondition.new('C')
    cond = a.conjunction(b).conjunction(c)
    assert_equal('(A) && (B) && (C)', cond.to_code)
  end

  def test__conjuncted__other_same__same_other
    a = CeAtomicCondition.new('A')
    b = CeAtomicCondition.new('B')
    c = a.conjunction(b).conjunction(a)
    e = CeConjunctiveCondition.new([a, b])
    assert_equal(e.to_code, c.to_code)
  end

  def test__conjunction__unconditional_other__other
    u = CeUnconditionalCondition.instance
    a = CeAtomicCondition.new('A')
    c = CeConjunctiveCondition.new([u, a])
    assert_equal(a, c)
  end

  def test__conjunction__other_unconditional__other
    u = CeUnconditionalCondition.instance
    a = CeAtomicCondition.new('A')
    c = CeConjunctiveCondition.new([a, u])
    assert_equal(a, c)
  end

  def test__unconditional__conjuncted_condition__condition
    u = CeUnconditionalCondition.instance
    a = CeAtomicCondition.new('A')
    c = u.conjunction(a)
    assert_equal(a, c)
  end

  def test__condition__conjuncted_unconditional__condition
    u = CeUnconditionalCondition.instance
    a = CeAtomicCondition.new('A')
    c = a.conjunction(u)
    assert_equal(a, c)
  end

  
end
