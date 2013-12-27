# encoding: utf-8

require 'helper'

require 'minitest/autorun'
require 'backerup/version'

class TestVersion < MiniTest::Unit::TestCase
  def test_version
    assert_equal('0.0.2', BackerUp::VERSION)
  end
end
