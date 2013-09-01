# encoding: utf-8

require 'helper'

require 'minitest/autorun'
require 'backerup/backups'

class TestBackup < MiniTest::Unit::TestCase
  def test_backup
    backup = BackerUp::Backups::Backup.new(
      :root => 'root',
      :active_path => 'bob',
      :static_path => 'bob',
      :partial_path => 'bob',
      :host => 'bob',
      :path => 'bob',
      :bwlimit => 1000,
      :data => 'bob',
      :all_paths => [ 'bob', 'bill' ],
    )
    assert_kind_of(BackerUp::Backups::Backup, backup)
  end
end

class TestBackups < MiniTest::Unit::TestCase
  def test_version
    assert_equal(BackerUp::Backups.class, Class);
  end
end
