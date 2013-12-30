require 'helper'

require 'backerup/configure'

describe BackerUp::Hostname do
  describe '#hostname' do
    it 'it returns a string' do
      BackerUp::Hostname.hostname.must_be_instance_of String
      BackerUp::Hostname.hostname.must_be_instance_of String
    end
  end
end

describe BackerUp::Configure::Group do
  before do
    @c= BackerUp::Configure::Group.new({})
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
  describe '#host' do
    it 'throws an exception with no arguments' do
      lambda { @c.host }.must_raise ArgumentError
    end
    it 'requires only one hostname' do
      lambda { @c.host('bob', 'bob') }.must_raise ArgumentError
    end
    it 'outputs a note with no block' do
      lambda { @c.host('bob') }.must_output "A host (bob) without a block is not very helpful\n"
    end
    it 'pushes data on to the @eval list' do
      @c.instance_variable_get('@eval').size.must_equal 0
      @c.host('bob') { source('::bob') }
      @c.instance_variable_get('@eval').size.must_equal 1
    end
  end
  describe '#source' do
    it 'throws an exception with no arguments' do
      lambda { @c.source }.must_raise ArgumentError
    end
    it 'requires only hostname an sourse' do
      lambda { @c.source('bob', '/bob', '::bob', 'extra') }.must_raise ArgumentError
    end
    it 'pushes data on to the @eval list' do
      @c.instance_variable_get('@eval').size.must_equal 0
      @c.source('bob', '/bob', '::bob').must_be_instance_of BackerUp::Configure::Group
      @c.instance_variable_get('@eval').size.must_equal 1
    end
  end
  describe '#backup' do
    it 'throws an exception with no arguments' do
      lambda { @c.backup }.must_raise ArgumentError
    end
    it 'requires only hostname an sourse' do
      lambda { @c.backup('bob', '/bob', 'extra') }.must_raise ArgumentError
    end
    it 'pushes data on to the @eval list' do
      @c.instance_variable_get('@eval').size.must_equal 0
      @c.backup('bob', '/bob').must_be_instance_of BackerUp::Configure::Group
      @c.instance_variable_get('@eval').size.must_equal 1
    end
  end
  describe '#skip' do
    it 'throws an exception' do
      lambda { @c.skip }.must_raise BackerUp::Configure::Skip
    end
  end
end

#describe BackerUp::Configure::Host do
#end

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

