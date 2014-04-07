# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'fileutils'
require 'open3'
require 'date'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  # This class contains the collector application of backerup system
  class AppCopier
    # Display unix commands that will effect simular results to running this command
    def self.dry_run(root)
      Copier.new(root).dry_run
    end
    # Copy the .static directory once right now
    def self.run(root)
      Copier.new(root).run
    end
    def self.trun(root)
      c = Copier.new(root)
      t = c.trun
      return t
    end
  end
  # Class that makes copies of the .static directory tree
  class Copier
    # The Copier instance requires a list of paths that contain .static directory trees
    attr_reader :root
    def initialize(root, extra = {})
      @root = root;
      @paths = []
    end
    # verbose flag set
    def verbose?
      false
    end
    # run as daemaon that cleans a root periodicly
    def trun
      @thread = Thread.new {
	@running = true
	while @running
	  begin
	    BackerUp::logger.info("First copy in #{(60 / @root.copy_factor) - (Time.now.min % (60 / @root.copy_factor))} minutes")
	    while @running
	      # FIXME should be able to set between 4 times per hour 
	      time = Time.now
	      if ((time.hour * 60) + time.min) % (60 / @root.copy_factor) == 0
		BackerUp::logger.info("Starting copy for #{@root}")
		run
	        BackerUp::logger.info("Copy took #{Time.now - time}")
		minutes = ((time.hour * 60) + time.min)
	        BackerUp::logger.info("Next copy in #{(60 / @root.copy_factor) - (minutes % (60 / @root.copy_factor))} minutes")
	      end
	      sleep 60 - (Time.now.sec + Time.now.nsec/1000000000.0)
	    end
	  rescue => x
	    BackerUp::logger.error("Error in copy: #{x}")
	  end
	end
      }
      self
    end
    # Display unix commands that will effect simular results to running this command
    def dry_run
      start_time = DateTime.now.strftime "%Y%m%d%H%M%S"
      @paths = Array.new
      [ @root.path ].each do |root|
        @paths.push Hash[
          :source => File.join(root, '.static'),
          :temp => File.join(root, ".copy-" + start_time), 
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
    def stop
      while @paths.size > 0
        cntrl = @paths.pop
	FileUtils.remove_entry_secure(cntrl[:temp], :force => true)
        Process.kill 'TERM', cntrl[:pid] if cntrl[:pid]
      end
    end
    # make a copy of the .static directory
    def run
      start_time = DateTime.now.strftime "%Y%m%d%H%M%S"
      @paths = Array.new
      ret = Array.new
      at_exit do
        @paths.each do |path|
          FileUtils.remove_entry_secure(path[:temp], :force => true)
        end
      end
      root_path = @root.path
      @paths.push Hash[
        :root => root_path,
        :source => File.join(root_path, '.static'),
        :temp => File.join(root_path, ".copy-" + start_time), 
        :dest => File.join(root_path, "hourly-" + start_time), 
      ] 
      @paths.each do |path|
	BackerUp::logger.info("copy #{path}")
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
        @paths.each do |path|
	  path[:done] = true unless path[:thread]
	end
	@paths = @paths.keep_if { |p| !p[:done] }
        @paths.each do |path|
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
          end
        end
	@paths = @paths.keep_if { |p| !p[:done] }
      end
      ret
    end # def run
  end # class Copier
end # module
