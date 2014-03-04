require 'shelper'

require 'backerup/collector'
require 'minitest/mock'

describe BackerUp::Collector do
  describe '#initialize' do
    it 'fails without enough arguments' do
      lambda { BackerUp::Collector.new() }.must_raise ArgumentError
    end
    it 'returns a BackerUp::Collector object' do
      @backup = MiniTest::Mock.new()
      BackerUp::Collector.new(@backup).must_be_kind_of BackerUp::Collector
    end
  end
  describe '#run' do
    before do
      @backup = MiniTest::Mock.new()
      @backup.expect(:active_path, '/tmp/active')
      @backup.expect(:static_path, '/tmp/static')
      @backup.expect(:partial_path, nil)
      @backup.expect(:grab_network, nil)
      @backup.expect(:release_network, nil)
      command_data = %Q{bash -c 'echo "cd+++++++++|./|4096|"
      echo "cd+++++++++|a/|4096|"
      echo ">f+++++++++|a/a|0|d41d8cd98f00b204e9800998ecf8427e"'}
      @backup.expect(:command, command_data)
      @collector = BackerUp::Collector.new(@backup)
#      @backup.verify
    end
    it 'does many things' do
      @collector.run.must_be_nil
    end
  end
end

