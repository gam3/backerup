require 'shelper'

require 'backerup/logger'

describe 'BackerUp' do
  describe '.logger' do
    it 'returns a nil early' do
      BackerUp.logger.must_be_instance_of BackerUp::Logger::Logger
    end
  end
  describe '.logger=' do
    it 'can be set' do
      BackerUp.logger = 'bob'
      BackerUp.logger.must_equal 'bob'
      BackerUp.logger = nil
    end
  end
end

