require 'pp'

require 'fileutils'
require 'open3'
require 'date'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  # This class contains the collector application of backerup system
  class AppCopier
    # Display unix commands that will effect simular results to running this command
    def self.dry_run
      Copier.new(Backups).dry_run
    end
    # Copy the .static directory
    def self.run
      Copier.new(Backups).run
    end
    def self.trun(root)
      Cleaner.new(root).trun
    end
  end
  # Class that makes copies of the .static directory tree
  class Copier
    # The Copier instance requires a list of paths that contain .static directory trees
    def initialize(backups)
      @backups = backups;
    end
    # run as daemaon that cleans a root periodicly
    def trun
      Thread.new {
        @running = true
        while @running
          clean
	  sleep 3600 * rand + 3600
	  puts "cleaning"
	end
      }
    end
    # Display unix commands that will effect simular results to running this command
    def dry_run
      start_time = DateTime.now.strftime "%Y%m%d%H%M%S"
      @paths = Array.new
      @backups.roots.each do |root|
        @paths.push Hash[
	  :source => File.join(root, '.static'),
	  :temp => File.join(root, ".copy"), 
	  :dest => File.join(root, "hourly-" + start_time), 
	] 
      end
      @paths.each do |path|
        puts "cp -rl #{path[:source]} #{path[:temp]}"
      end
      @paths.each do |path|
	puts "mv #{path[:temp]} #{path[:dest]}"
      end
      @paths.map { |p| p[:dest] }
    end
    # Use hardlinks to make a copy of a directory tree
    def run
      start_time = DateTime.now.strftime "%Y%m%d%H%M%S"
      @paths = Array.new
      ret = Array.new
      at_exit do
	@paths.each do |root|
          FileUtils.remove_entry_secure(path[:temp], :force => true)
	end
      end
      @backups.roots.each do |root|
        @paths.push Hash[
	  :root => root,
	  :source => File.join(root, '.static'),
	  :temp => File.join(root, ".copy"), 
	  :dest => File.join(root, "hourly-" + start_time), 
	] 
      end
      @paths.each do |path|
        if File.exist?(path[:temp])
          BackerUp::logger.info("copy in progress for #{path[:root]}")
	  next
	end
        if !File.exist?(path[:source])
          BackerUp::logger.info("Path not found #{path[:source]}")
	  next
	end
        path[:thread] = Thread.new do
	  Open3.popen3( "cp -rl #{path[:source]} #{path[:temp]}") do |stdin, stdout, stderr, wait_thr|
	    stdin.close
            pid = wait_thr.pid
	    path[:pid] = pid
	    exit_status = wait_thr.value
	    path[:pid] = nil
	    path[:exit] = exit_status
	  end
	end
      end
      while @paths.size > 0
        paths = @paths
	@paths = Array.new
        paths.each do |path|
	  next unless path[:thread]
	  if path[:thread].join(1)
	    Open3.popen3( "mv #{path[:temp]} #{path[:dest]}") do |stdin, stdout, stderr, wait_thr|
	      stdin.close
	      pid = wait_thr.pid
	      exit_status = wait_thr.value
	      if exit_status.exitstatus == 0
	        ret.push path[:dest]
	      end
	      path[:done] = true
	    end
	  else
	    # Make sure the cleaner does not remove this directory
            FileUtils.touch(path[:temp])
	    @paths.push path
	  end
	end
      end
      ret
    end # def run
  end # class Collector
end # module
