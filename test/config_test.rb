# encoding: utf-8

require 'test_helper'

require 'backerup/configure'

class TestConfigure < MiniTest::Unit::TestCase
  def setup
    BackerUp::Backups.clear
    @configuration = BackerUp::Configure.new
  end
  def test_configure1
    File.open('test/config1', 'r') do |file|
      data = file.read
      @configuration.top data, 'test/config1'
    end
  end
  def test_configure2
    File.open('test/config2', 'r') do |file|
      data = file.read
      @configuration.top data, 'test/config2'
    end
  end
  def test_configure3
    File.open('test/config3', 'r') do |file|
      data = file.read
      @configuration.top data, 'test/config3'
    end
  end
  def test_configure4
    File.open('test/config4', 'r') do |file|
      data = file.read
      @configuration.top data, 'test/config4'
    end
  end
  def test_configure5
    File.open('test/config5', 'r') do |file|
      data = file.read
      assert_raises RuntimeError do
	@configuration.top(data, 'test/config5')
      end
    end
  end
end

