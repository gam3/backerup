# encoding: utf-8

require 'helper'

require 'minitest/autorun'
require 'backerup/configure'

require 'pp'

class TestConfigure < MiniTest::Unit::TestCase
  def setup
    @configureation = BackerUp::Configure.new
  end
  def test_configure1
    File.open('test/config1', 'r') do |file|
      data = file.read
      @configureation.instance_eval data
#pp @configureation
    end
  end
  def test_configure2
    File.open('test/config2', 'r') do |file|
      data = file.read
      @configureation.instance_eval data
#pp @configureation
    end
  end
end
