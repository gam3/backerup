
require 'spec_helper'

require 'backerup/backups'

describe BackerUp::Root do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Root.new() }.must_raise ArgumentError
    end
    it 'returns a BackerUp::Root object' do
      BackerUp::Root.new('path').must_be_kind_of BackerUp::Root
    end
  end
  describe '#copy_factor' do
    before do
      @b = BackerUp::Root.new('path')
    end
    it 'returns a number' do
      @b.copy_factor.must_be_kind_of Fixnum
    end
  end
end

describe BackerUp::Backups do
  describe '.get' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Backups.get() }.must_raise ArgumentError
    end
    it 'fails if there are too many arguments' do
      lambda { BackerUp::Backups.get('bob', '/bob', '::bob') }.must_raise ArgumentError
    end
  end
  describe '.each' do
    before do
    end
    it 'iterates ovar all sources' do
      BackerUp::Backups.get('bob', '/bob')
      BackerUp::Backups.get('bob', '/bob/smith')
      BackerUp::Backups.each do |b|
        b.must_be_instance_of BackerUp::Backup
      end
    end
  end
  describe '.clear' do
    before do
    end
    it 'clears all sources' do
      BackerUp::Backups.get('bob', '/bob').must_be_instance_of BackerUp::Backup
      BackerUp::Backups.get('bill', '/bill').must_be_instance_of BackerUp::Backup
      BackerUp::Backups.size.must_equal 2
      BackerUp::Backups.clear
      BackerUp::Backups.size.must_equal 0
    end
  end
end

describe BackerUp::Sources do
  describe '.get' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Sources.get() }.must_raise ArgumentError
    end
    it 'fails if there are multiple paths for a source' do
      BackerUp::Sources.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
      lambda { BackerUp::Sources.get('bob', '/bob',  '::bill') }.must_raise ArgumentError
      lambda { BackerUp::Sources.get('bob', '/bill', '::bob') }.must_raise ArgumentError
      BackerUp::Sources.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
    end
  end
  describe '#get' do
    before do
      @i = BackerUp::Sources.instance
    end
    it 'fails without enough arguments' do
      lambda { @i.get() }.must_raise ArgumentError
    end
    it 'fails if there are multiple paths for a source' do
      @i.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
      lambda { @i.get('bob', '/bob',  '::bill') }.must_raise ArgumentError
      lambda { @i.get('bob', '/bill', '::bob') }.must_raise ArgumentError
      @i.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
    end
  end
  describe '.clear' do
    before do
    end
    it 'clears all sources' do
      BackerUp::Sources.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
      BackerUp::Sources.get('bill', '/bill',  '::bill').must_be_instance_of BackerUp::Source
      BackerUp::Sources.size.must_equal 2
      BackerUp::Sources.clear
      BackerUp::Sources.size.must_equal 0
    end
  end
  describe '#clear' do
    before do
      @i = BackerUp::Sources.instance
    end
    it 'clears all sources' do
      @i.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
      @i.get('bill', '/bill',  '::bill').must_be_instance_of BackerUp::Source
      @i.size.must_equal 2
      @i.clear
      @i.size.must_equal 0
    end
  end
  describe '#each_path' do
    before do
      @i = BackerUp::Sources.instance
    end
    it 'clears all sources' do
      @i.get('bob', '/bob',  '::bob').must_be_instance_of BackerUp::Source
      @i.get('bill', '/bill',  '::bill').must_be_instance_of BackerUp::Source
      @i.each_path do |p|
        p.must_be_instance_of String
      end
    end
  end
end

describe BackerUp::Roots do
  describe '.get' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Roots.get() }.must_raise ArgumentError
    end
    it 'fails if there are too many arguments' do
      lambda { BackerUp::Roots.get('/bob', 'x') }.must_raise ArgumentError
    end
    it 'requires one argument' do
      BackerUp::Roots.get('/bob').must_be_instance_of BackerUp::Root
    end
  end
  describe '#clear' do
    before do
      @r = BackerUp::Roots.instance
    end
    it 'clears all sources' do
      @r.clear
      @r.get('/bob').must_be_instance_of BackerUp::Root
      @r.get('/bill').must_be_instance_of BackerUp::Root
      @r.size.must_equal 2
      @r.clear
      @r.size.must_equal 0
    end
  end
  describe '.clear' do
    before do
    end
    it 'clears all sources' do
      BackerUp::Roots.clear
      BackerUp::Roots.get('/bob').must_be_instance_of BackerUp::Root
      BackerUp::Roots.get('/bill').must_be_instance_of BackerUp::Root
      BackerUp::Roots.size.must_equal 2
      BackerUp::Roots.clear
      BackerUp::Roots.size.must_equal 0
    end
  end
  describe '#size' do
    before do
      @r = BackerUp::Roots.instance
    end
    it 'returns a number' do
      @r.size.must_be_kind_of Fixnum
    end
  end
  describe '.size' do
    it 'returns a number' do
      BackerUp::Roots.size.must_be_kind_of Fixnum
    end
  end
end

describe BackerUp::Hosts do
  describe '.get' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Hosts.get() }.must_raise ArgumentError
    end
    it 'fails if there are too many arguments' do
      lambda { BackerUp::Hosts.get('/bob', 'x') }.must_raise ArgumentError
    end
    it 'requires one argument' do
      BackerUp::Hosts.get('/bob').must_be_instance_of BackerUp::Host
    end
  end
  describe '.clear' do
    before do
    end
    it 'clears all sources' do
      BackerUp::Hosts.clear
      BackerUp::Hosts.get('/bob').must_be_instance_of BackerUp::Host
      BackerUp::Hosts.get('/bill').must_be_instance_of BackerUp::Host
      BackerUp::Hosts.size.must_equal 2
      BackerUp::Hosts.clear
      BackerUp::Hosts.size.must_equal 0
    end
  end
end
