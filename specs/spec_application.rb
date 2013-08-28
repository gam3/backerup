
require 'helper'

require 'backerup/application'

module BackerUp
  describe Application do
    describe '#initialize' do
      it 'has an initializer' do
        Application.new().must_be_instance_of Application
      end
      it 'does not accept arguments' do
        lambda { Application.new( 1 ) }.must_raise ArgumentError
      end
    end
  end
end

