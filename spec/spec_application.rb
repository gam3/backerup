
require 'helper'

require 'backerup/application'

describe BackerUp::AppCollector do
  describe '#initialize' do
    it 'has an initializer' do
      BackerUp::AppCollector.new().must_be_instance_of BackerUp::AppCollector
    end
    it 'does not accept arguments' do
      lambda { BackerUp::AppCollector.new( 1 ) }.must_raise ArgumentError
    end
  end
end

