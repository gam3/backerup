# encoding: utf-8

require 'test_helper'

require 'minitest/autorun'
require 'backerup/version'

class TestVersion < MiniTest::Unit::TestCase
  def test_version
    assert_equal('0.0.4', BackerUp::VERSION)
  end
end
