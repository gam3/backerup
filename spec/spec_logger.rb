
require 'helper'

require 'backerup/logger'

describe BackerUp::Logger do
  describe '#logger' do
    it 'returns a nil early' do
      BackerUp::logger.must_be_nil
    end
  end
  describe '#logger=' do
    it 'can be set' do
      BackerUp::logger = 'bob'
      BackerUp::logger.must_equal 'bob'
    end
  end
end

