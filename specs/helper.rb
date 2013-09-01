
#require 'minitest/spec'
require 'minitest/autorun'

if ENV['COVERAGE'] == 'test'
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/specs/"
  end
end
