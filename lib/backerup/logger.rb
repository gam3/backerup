require 'logger'

module BackerUp
  # This is the global logger module most other classes use this to
  # do logging
  module Logger
    # This class overloads the ruby Logger class.
    class Logger < ::Logger
    end
  end
  # set of get the logger object
  class <<self
    attr_accessor :logger
  end
end
