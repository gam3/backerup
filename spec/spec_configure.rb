
require 'helper'

require 'backerup/configure'

describe BackerUp::Configure do
  describe '#initialize' do
    it 'returns a Configure object' do
      BackerUp::Configure.new().must_be_instance_of BackerUp::Configure
    end
    it 'does not accept arguments' do
      lambda { BackerUp::Configure.new( 1 ) }.must_raise ArgumentError
    end
  end
end

