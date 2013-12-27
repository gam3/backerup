
require 'fileutils'
require 'open3'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  # This class contains the collector application of backerup system
  class AppCleaner
    def initialize(roots)
      @roots = roots
    end
    def run
      threads = Array.new
      @roots.each do |root|
        threads.push Thread.new { Cleaner.clean(root) }
      end
      while threads.size > 0
#	threads = threads.find_all { |thread| thread.alive? }
	threads = threads.find_all { |thread| !thread.join(1) }
      end
    end
  end
  # Clean up the backup by sieving the directories
  class Cleaner
    def self.clean(root)
puts "#{root}"
    end
  end # class Cleaner
  class << self
    # Current BarkerUp Application
    def cleaner
      @application ||= BackerUp::AppCleaner.new
    end

    # Set the current BackerUp application object.
    def cleaner=(app)
      @application = app
    end
  end
end # module
