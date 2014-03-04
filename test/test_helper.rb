
if ENV['COVERAGE'] == 'test'
  require 'simplecov'
  require 'simplecov-shtml'
  SimpleCov.start do
    formatter = SimpleCov::Formatter::SHTMLFormatter
    add_filter "/test/"
    add_filter "/specs/"
  end
end

require 'minitest/autorun'
