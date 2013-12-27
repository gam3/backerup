
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
  end
end

