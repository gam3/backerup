require 'spec_helper'

require 'backerup/configure'

module BackerUp
  describe Configure::Source do
    describe '#initialize' do
      it 'returns a Configure::Source object' do
	BackerUp::Configure::Source.new('host', 'path', 'source_path').must_be_instance_of BackerUp::Configure::Source
      end
    end
    describe '#backup' do
      before do
	@c= BackerUp::Configure::Source.new('host', 'path', 'source_path')
      end
      it 'takes one or no arguments' do
	@c.backup().must_be_instance_of BackerUp::Configure::Source
	@c.backup('/bob').must_be_instance_of BackerUp::Configure::Source
	@c.backup('bob').must_be_instance_of BackerUp::Configure::Source
	lambda { @c.backup('bob', 'bob') }.must_raise ArgumentError
      end
    end
    # describe '.network' do
    # end
  end
end

