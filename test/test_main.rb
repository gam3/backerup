# encoding: utf-8

require 'thelper'

require 'minitest/autorun'
require 'backerup/version'

class TestVersion < MiniTest::Unit::TestCase
  def test_version
    assert_equal('0.0.3', BackerUp::VERSION)
  end
end
