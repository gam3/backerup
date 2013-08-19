
require 'helper'

require 'backerup/configure'

module BackerUp
  describe Configure do
    describe '#initialize' do
      it 'returns a Configure object' do
        Configure.new().must_be_instance_of Configure
      end
      it 'does not accept arguments' do
        lambda { Configure.new( 1 ) }.must_raise ArgumentError
      end
    end
    describe '#new' do
      it 'does thngs' do
        true
      end
    end
  end
end

