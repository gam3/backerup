require 'pp'

require 'fileutils'
require 'open3'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  # This class contains the collector application of backerup system
  class AppCopier
    # run the copier application
    def self.run
      start_time = DateTime.now.strftime "%Y%m%d%H%M%S"
      @paths = Array.new
      at_exit do
	@paths.each do |root|
          FileUtils.remove_entry_secure(path[:temp], :force => true)
	end
      end
      Backups.roots.each do |root|
        @paths.push Hash[
	  :source => File.join(root, '.static'),
	  :temp => File.join(root, ".hourly-" + start_time), 
	  :dest => File.join(root, "hourly-" + start_time), 
	] 
      end
      @paths.each do |path|
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
	  if path[:thread].join(1)
	    Open3.popen3( "mv #{path[:temp]} #{path[:dest]}") do |stdin, stdout, stderr, wait_thr|
	      stdin.close
	      pid = wait_thr.pid
	      exit_status = wait_thr.value
	      path[:done] = true
	    end
	  else
	    @paths.push path
	  end
	end
      end
    end # def run
  end # class Collector
end # module
