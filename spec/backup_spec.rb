
require 'spec_helper'

require 'backerup/backups'

describe BackerUp::Backup do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Backup.new() }.must_raise ArgumentError
    end
    it 'returns a BackerUp::Backup object' do
      BackerUp::Backup.new('host', 'path').must_be_kind_of BackerUp::Backup
    end
    it 'returns a BackerUp::Backup object' do
    end
  end
  describe '#exclude_paths' do
    before do
      @b = BackerUp::Backup.new('host', 'path')
    end
    it 'returns and Array' do
      @b.exclude_paths.must_be_kind_of Array
    end
  end
  describe '#to_s' do
    before do
      @b = BackerUp::Backup.new('host', 'path')
    end
    it 'returns and Array' do
      @b.to_s.must_equal "backup: host '/home/gam3/src/backerup/path' 'NO SOURCE AVAILABLE'"
    end
  end
end

