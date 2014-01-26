
require 'helper'

require 'backerup/backups'

describe BackerUp::Backup do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Backup.new() }.must_raise ArgumentError
    end
    it 'returns a BackerUp::Backups::Backup object' do
      BackerUp::Backup.new('host', 'path').must_be_kind_of BackerUp::Backup
    end
    it 'returns a BackerUp::Backups::Backup object' do
    end
  end
end

describe BackerUp::Backups do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Backups.get() }.must_raise ArgumentError
    end
  end
end

describe BackerUp::Sources do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Sources.get() }.must_raise ArgumentError
    end
    it 'fails if multiple paths for a source' do
      BackerUp::Sources.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
      lambda { BackerUp::Sources.get('bob', '/bob',  '::bill') }.must_raise RuntimeError
      lambda { BackerUp::Sources.get('bob', '/bill', '::bob') }.must_raise RuntimeError
      BackerUp::Sources.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
    end
  end
end

