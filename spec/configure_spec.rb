require 'shelper'

require 'backerup/configure'

describe BackerUp::Hostname do
  describe '.hostname' do
    it 'it returns a string' do
      BackerUp::Hostname.hostname.must_be_instance_of String
      BackerUp::Hostname.hostname.must_be_instance_of String
    end
  end
end

describe BackerUp::Configure::Common do
# these are defined in the Common Module
  before do
    post_class = Class.new
    post_class.class_eval <<EOF
include BackerUp::Configure::Common
def initialize
 @skipped_hostsnames = Array.new
end
EOF
    @c = post_class.new
  end
  describe '#skip' do
    it 'throws an Skip Exception' do
      lambda { @c.skip() }.must_raise BackerUp::Configure::Skip
    end
  end
  describe '#hostname' do
    it 'requires a hostname' do
      lambda { @c.hostname() }.must_raise ArgumentError
    end
    it 'must return true for current host' do
      @c.hostname(BackerUp::Hostname.hostname).must_equal true
    end
    it 'return false for other host' do
      @c.hostname('not_test').must_equal false
    end
  end
end

describe BackerUp::Configure do
  describe '#initialize' do
    it 'returns a Configure object' do
      BackerUp::Configure.new().must_be_instance_of BackerUp::Configure
    end
    it 'does not accept arguments' do
      lambda { BackerUp::Configure.new( 1 ) }.must_raise ArgumentError
    end
  end
end

describe BackerUp::Configure do
  before do
    @c= BackerUp::Configure.new()
  end
  describe '#top' do
    it 'requires an argument' do
      lambda { @c.top() }.must_raise ArgumentError
    end
  end
end

