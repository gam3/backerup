
require 'test_helper.rb'

require 'backerup/version'

class Test000 < MiniTest::Unit::TestCase
  def setup
  end
  def test_version
    version = nil
    File.open('./debian/changelog', 'r') do |file|
      file.each_line do |line|
        line.chomp!
        if m = line.match(/^backerup \(([0-9.]*)\) /)
	  version = m[1].to_s
	  break
	end
      end
    end
    assert_equal version, BackerUp::VERSION
  end
end
