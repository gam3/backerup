require 'shelper'

require 'backerup/backups'

describe BackerUp::Host do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Host.new() }.must_raise ArgumentError
    end
    it 'returns a BackerUp::Host object' do
      BackerUp::Host.new('hostname').must_be_kind_of BackerUp::Host
    end
    it 'returns a BackerUp::Host object' do
    end
  end
  describe '#networks' do
    before do
      @b = BackerUp::Host.new('host')
    end
    it 'returns an Array' do
      @b.networks.must_be_kind_of Array
    end
  end
  describe '#to_s' do
    before do
      @b = BackerUp::Host.new('host')
    end
    it 'returns' do
      @b.to_s.must_be_kind_of String
    end
  end
end

