# encoding: utf-8

require 'test_helper'

require 'backerup/logger'

class TestLogger < MiniTest::Unit::TestCase
  def test_logger
    BackerUp::logger = 'bob'
    assert_equal BackerUp::logger, 'bob'
  end
end
