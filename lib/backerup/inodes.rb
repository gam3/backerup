# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'date'
require 'time'
require 'fileutils'
require 'set'

require 'backerup/backups'

module BackerUp
  # This class contains the collector application of backerup system
  class AppInodes
    # initialize
    def initialize(roots)
      @roots = roots
    end
    # show what actions this command will do
    def self.dry_run
      self.run(true)
    end
    # Run the inodes application
    def self.run(dry_run = false)
      @roots = Array.new
      Backups.roots.each do |root|
        @roots.push root
      end
      threads = Array.new
      @roots.each do |root|
        threads.push Thread.new { Inodes.create(root) }
      end
      while threads.size > 0
	threads = threads.find_all { |thread| !thread.join(1) }
      end
    end
  end
  # Create an .inodes directory for a given root
  class Inodes
    # creat and populate the .inodes directory
    def self.create(root)
    end
  end # class Cleaner
end # module
__END__
