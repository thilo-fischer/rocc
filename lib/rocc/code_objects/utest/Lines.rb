#!/usr/bin/ruby19 -w
# -*- coding: utf-8 -*-

#require_relative 'Lines'
#require_relative 'File'
require_relative '../../ooccor.rb'

require 'test/unit'
require 'mocha/setup'

class TC_CoPhysicLine < Test::Unit::TestCase

  def test_origin_offset
    origin = CoFile.new nil, '', 0
    origin_offset = 42
    l = CoPhysicLine.new(origin, 'text', origin_offset)
    assert_equal(origin_offset, l.origin_offset)
  end

  def test_line_number
    origin = CoFile.new nil, '', 0
    origin_offset = 42
    l = CoPhysicLine.new(origin, 'text', origin_offset)
    assert_equal(origin_offset + 1, l.line_number)
  end

  def test_text
    origin = CoFile.new nil, '', 0
    text = 'foobar'
    l = CoPhysicLine.new(origin, text, 0)
    assert_equal(text, l.text)
  end

  def test_process_CleanEnv_EmptyLine
    origin = CoFile.new nil, '', 0
    text = ''
    env = ProcessingEnvironment.new
    pl = CoPhysicLine.new(origin, text, 0)
    ll = CoLogicLine.new(pl, text)
    CoLogicLine.expects(:new).with(pl, text).returns(ll)
    ll.expects(:process).with(env).returns(42)
    result = pl.process(env)
    assert_equal(42, result)
  end

  def test_process_CleanEnv_AutonomousLine
    origin = CoFile.new nil, '', 0
    text = ' foo '
    env = ProcessingEnvironment.new
    pl = CoPhysicLine.new(origin, text, 0)
    ll = CoLogicLine.new(pl, text)
    CoLogicLine.expects(:new).with(pl, text).returns(ll)
    ll.expects(:process).with(env).returns(42)
    result = pl.process(env)
    assert_equal(42, result)
  end

  def test_process_CleanEnv_BackslashWhitespace
    origin = CoFile.new nil, '', 0
    text = ' \\ '
    env = ProcessingEnvironment.new
    pl = CoPhysicLine.new(origin, text, 0)
    ll = CoLogicLine.new(pl, text)
    CoLogicLine.expects(:new).with(pl, text).returns(ll)
    ll.expects(:process).with(env).returns(42)
    result = pl.process(env)
    assert_equal(42, result)
  end

  def test_process_CleanEnv_ContinuingLine_ResultNil
    origin = CoFile.new nil, '', 0
    text = ' foo \\'
    env = ProcessingEnvironment.new
    pl = CoPhysicLine.new(origin, text, 0)
    result = pl.process(env)
    assert_equal(nil, result)
  end

  def test_process_CleanEnv_ContinuingLine_RemainderInEnv
    origin = CoFile.new nil, '', 0
    text = ' foo \\'
    env = ProcessingEnvironment.new
    pl = CoPhysicLine.new(origin, text, 0)
    pl.process(env)
    assert_equal([pl], env.remainders[CoPhysicLine])
  end

  def test_process_CleanEnv_ContinuingLine2_RemainderInEnv
    origin = CoFile.new nil, '', 0
    env = ProcessingEnvironment.new

    text0 = ' foo \\'
    pl0 = CoPhysicLine.new(origin, text0, 0)
    pl0.process(env)

    text1 = ' bar \\'
    pl1 = CoPhysicLine.new(origin, text1, 0)
    pl1.process(env)

    assert_equal([pl0, pl1], env.remainders[CoPhysicLine])
  end

  def test_process_CleanEnv_ContinuingLine3_CreateAndProcessLogicLine
    origin = CoFile.new nil, '', [ ' foo \\', ' bar ' ]
    env = ProcessingEnvironment.new

    text = ' foo bar '

    text0 = ' foo \\'
    pl0 = CoPhysicLine.new(origin, text0, 0)
    text1 = ' bar '
    pl1 = CoPhysicLine.new(origin, text1, 1)
    range = pl0 .. pl1

    ll = CoLogicLine.new(range, text)
    CoLogicLine.expects(:new).with(range, text).returns(ll)
    ll.expects(:process).with(env).returns(42)

    pl0.process(env)

    pl1.process(env)
  end

end
