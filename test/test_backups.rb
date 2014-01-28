# encoding: utf-8

require 'thelper'

require 'minitest/autorun'
require 'backerup/backups'

require 'pp'

class TestBackup < MiniTest::Unit::TestCase
  def test_backup
    @backups = BackerUp::Backups.instance
    @sources = BackerUp::Sources.instance
    @backups.get('demeter','/etc/q/bob/bob')
    @backups.get('demeter','/etc/q/bill')
    @sources.get('demeter', '/etc/', '::etc')
    @sources.get('demeter', '/etc/bob', '::etc/bob')
    @sources.get('demeter', '/etc/bill', '::etc/bill')
    backup = @backups.get('demeter','/etc/q')
    backup.set_defaults(
      :partial => true
    )

    assert_equal(
    'rsync --archive --update --out-format=%i|%n|%l|%C --delete --partial --partial-dir=/opt/backerup/.partial/demeter/etc/q --bwlimit=5000 --exclude=bob/bob --exclude=bill demeter::etc/q/. /opt/backerup/.active/demeter/etc/q',
                  backup.command.map{ |x| x }.join(' '))
  end
end

