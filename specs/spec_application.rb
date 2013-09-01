
require 'helper'

require 'backerup/application'

describe BackerUp::Application do
  describe '#initialize' do
    it 'has an initializer' do
      BackerUp::Application.new().must_be_instance_of BackerUp::Application
    end
    it 'does not accept arguments' do
      lambda { BackerUp::Application.new( 1 ) }.must_raise ArgumentError
    end
  end
end

