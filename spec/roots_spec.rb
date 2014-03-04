
require 'spec_helper'

require 'backerup/backups'

describe BackerUp::Roots do
  describe '.get' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Roots.get() }.must_raise ArgumentError
    end
    it 'returns a Root object' do
      BackerUp::Roots.get('/opt/backerup').must_be_instance_of BackerUp::Root
    end
  end
  describe '#each' do
    it 'saves each uniq root' do
      BackerUp::Roots.get('/opt/backerup/b').must_be_instance_of BackerUp::Root
      BackerUp::Roots.get('/opt/backerup/a').must_be_instance_of BackerUp::Root
      BackerUp::Roots.get('/opt/backerup/a').must_be_instance_of BackerUp::Root
      BackerUp::Roots.instance.each.to_a.size.must_equal 2
    end
  end
end

describe BackerUp::Root do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Root.new }.must_raise ArgumentError
    end
    it 'returns a Root object' do
      BackerUp::Root.new('/opt/backerup').must_be_instance_of BackerUp::Root
    end
  end
end
