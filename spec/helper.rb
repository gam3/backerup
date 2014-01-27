puts "HELPER"

if ENV['COVERAGE'] == 'test'
  require 'simplecov'
  SimpleCov.start do
    command_name 'Minitest::Spec'
#    add_filter "/test/"
    add_filter "/spec/"
  end
end


require 'minitest/autorun'
require 'minitest/spec'

