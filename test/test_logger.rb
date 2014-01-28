# encoding: utf-8

require 'thelper'

require 'minitest/autorun'
require 'backerup/logger'

class TestLogger < MiniTest::Unit::TestCase
  def test_logger
    BackerUp::logger = 'bob'
    BackerUp::logger.must_equal 'bob'
  end
end
