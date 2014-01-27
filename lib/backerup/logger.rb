# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
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
    # get the logger
    # get the current logger
    def logger
      if @logger.nil?
	@logger = Logger::Logger.new('/tmp/backerup.log')
      end
      @logger
    end
    # set the current logger
    def logger=(x)
      @logger = x
    end
  end
end
