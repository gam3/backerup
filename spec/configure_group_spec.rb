require 'spec_helper'

require 'backerup/configure'

describe BackerUp::Configure::Group do
  before do
    @c= BackerUp::Configure::Group.new({})
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
    it 'throws an exception without exactly 2 arguments' do
      lambda { @c.backup }.must_raise ArgumentError
      lambda { @c.backup('bob', '/bob', 'extra') }.must_raise ArgumentError
    end
    it 'returns a Group Object' do
      @c.backup('bob', '/bob').must_be_instance_of BackerUp::Configure::Group
    end
    it 'pushes data on to the @eval list' do
      @c.instance_variable_get('@eval').size.must_equal 0
      @c.backup('bob', '/bob').must_be_instance_of BackerUp::Configure::Group
      @c.instance_variable_get('@eval').size.must_equal 1
    end
  end
end
