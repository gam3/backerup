require 'spec_helper'

require 'backerup/copier'

require 'fileutils'

describe BackerUp::Copier do
  before do
    @mock = MiniTest::Mock.new
  end
  describe '#initialize' do
    it 'takes a single argument' do
       BackerUp::Copier.new @mock
    end
  end
end

describe BackerUp::Copier do
  before do
    @mock = MiniTest::Mock.new
    @mock.expect(:path, [ 'bob' ])
    @c = BackerUp::Copier.new @mock, :dryrun => true
  end
  describe '#dry_run' do
    it 'takes a single argument' do
       skip
       lambda { @c.dry_run }.must_output %r"cp -rl bob/.static bob/.copy\nmv bob/.copy bob/hourly-[0-9]*\n"
    end
  end
end

describe "BackerUp::Copier" do
  before do
    @mock = MiniTest::Mock.new
    @mock.expect(:path, '/opt/backerup/bob')
    @c = BackerUp::Copier.new @mock
  end
  describe '#dry_run' do
    it 'it outputs a string' do
       skip
       lambda { @c.dry_run }.must_output %r"cp -rl /opt/backerup/bob/.static /opt/backerup/bob/.copy\n"
    end
  end
end

describe "BackerUp::Copier" do
  before do
    @mock = MiniTest::Mock.new
    file = File.join('/tmp/backerup_test', "%05d" % (rand * 1000).round.to_s)
    @mock.expect(:path, file)
    @c = BackerUp::Copier.new @mock
    @output = ""
    BackerUp.logger = BackerUp::Logger::Logger.new(StringIO.open(@output,'w'))
  end
end

describe "BackerUp::Copier" do
  before do
    @mock = MiniTest::Mock.new
    @root = File.join('/tmp/backerup_test', "%05d" % (rand * 1000).round.to_s)
    @source = File.join(@root, '.static')
    @copy = File.join(@root, '.copy')
    @output = ""
    FileUtils.makedirs(@source)
    FileUtils.makedirs(@copy)
    %w( A B C D E F ).each do |name|
      FileUtils.touch(File.join(@source, name))
    end
    @mock.expect(:path, @root)
    @c = BackerUp::Copier.new @mock, :dry_run => true
    @output = ""
    BackerUp.logger = BackerUp::Logger::Logger.new(StringIO.open(@output,'w'))
  end
  describe '#run' do
    it 'logs busy' do
    end
  end
end

describe "BackerUp::Copier" do
  before do
    @mock = MiniTest::Mock.new
    @root = File.join('/tmp/backerup_test', "%05d" % (rand * 1000).round.to_s)
    @source = File.join(@root, '.static')
    FileUtils.makedirs(@source)
    %w( A B C D E F ).each do |name|
      FileUtils.touch(File.join(@source, name))
    end
    @mock.expect(:path, @root)
    @c = BackerUp::Copier.new @mock
    @output = ""
    BackerUp.logger = BackerUp::Logger::Logger.new(StringIO.open(@output,'w'))
  end
  after do
    FileUtils.remove_dir(@root)
  end
  describe '#run' do
    it 'creates a directory' do
      ret = @c.run
      ret.must_be_instance_of Array
      a = File.stat(File.join(@source, "A"))
      ret.each do |name|
        File.exist?(name).must_equal true
        a.ino.must_equal File.stat(File.join(name, "A")).ino
      end
    end
  end
end

