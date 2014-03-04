require 'spec_helper'

require 'backerup/backups'

describe BackerUp::Source do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Source.new() }.must_raise ArgumentError
    end
    it 'returns a BackerUp::Source object' do
      BackerUp::Source.new('hostname', 'path', 'source::path').must_be_kind_of BackerUp::Source
    end
    it 'returns a BackerUp::Source object' do
    end
  end
  describe '#source' do
    before do
      @b = BackerUp::Source.new('host', 'path', 'source::path')
    end
    it 'returns' do
      @b.source.must_be_kind_of String
      @b.source.must_equal 'source::path'
    end
  end
  describe '#to_s' do
    before do
      @b = BackerUp::Source.new('host', 'path', 'source::path')
    end
    it 'returns' do
      @b.to_s.must_be_kind_of String
    end
  end
end

