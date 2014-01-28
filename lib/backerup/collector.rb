# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'fileutils'
require 'open3'

require 'digest/sha1'

require 'backerup/configure'
configure = BackerUp::Configure.new


module BackerUp
  # This class contains the collector application of backerup system
  class AppCollector
    # show the actions of running this command once
    def self.dry_run
      backups = Backups.instance

      all  = Array.new

      backups.each do |backup|
        puts backup.command.map{ |x| Shellwords.escape(x) }.join(' ')
      end
    end
    # run the backups
    def self.trun(backup, extra = {})
      c = Collector.new(backup)
      t = c.trun
      return t
    end
    def self.run(backup)
      c = Collector.new(backup)
      t = c.run
    end
  end
  # There is one instance of this class for each backup
  class Collector
    # access the list of collector threads
    attr_reader :thread
    # access the list of current running threads
    attr_reader :current
    # the pid
    attr_reader :pid
    # initialize
    def initialize(backup, extra = {})
      @backup = backup
      @pid = nil
    end
    # is the collector due to run
    def due?
      if @thread
        return false
      end
      if @ended
        if Time.now - @ended < 10
          return false
        end
      end
      return true
    end
    # is the collector overdue to run
    def overdue?
      if @thread
        return false
      end
      if @ended
        if Time.now - @ended  < 3600
          return false
        end
      end
      return true
    end
    # @return [Logger::Logger] return a logging object
    def logfile
      BackerUp.logger
    end
    # run the collector in syncronous mode
    def stop
      if @pid
        Process.kill 'TERM', @pid
      end
    end
    # kill this cleaner
    def kill
      Process.kill 'TERM', @pid
      @pid = nil
    end

    # run the collector in asyncronous mode
    def trun
      @thread = Thread.new {
	@running = true
	while @running
	  begin
	    x = 60 + rand * 60
	    logfile.info "First collect of #{@backup} in less than #{x.round} minutes"
	    sleep x
	    while @running
	      logfile.info("collect #{@backup}")
	      run
	      x = 60 + rand * 60
	      logfile.info "Next collect of #{@backup} in less than #{x.round} minutes"
	      sleep x
	    end
	  rescue => x
	    BackerUp::logger.error("Error #{x}")
	  end
	end
      }
      self
    end

    def run
      backup = @backup
      begin
        FileUtils.mkdir_p( backup.active_path, :mode => 0755 )
        FileUtils.mkdir_p( backup.static_path, :mode => 0755 )
      rescue => x
        logfile.error "unable to create directory #{x.class}"
        return
      end
      if backup.partial_path
        begin
          FileUtils.mkdir_p( backup.partial_path, :mode => 0755 )
        rescue => x
          logfile.error "unable to create directory #{x}"
          return
        end
      end

      raise "You can't run the collector twice" if @rthread

      @started = Time.now
      @rthread = Thread.new do
        begin
          Open3.popen3(*backup.command) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            still_open = [stdout,stderr]
            @pid = wait_thr.pid
            start_time = nil
            active = nil
            need_log = nil
            while not still_open.empty?
              if need_log && Time.now - start_time > 0.01
                need_log = false
                (cnt, filename, size, md5) = @current
                case cnt[1]
                when 'f'
                  logfile.debug "starting: #{md5||'N/A'} #{"%10d" % size} '#{File.absolute_path(File.join(backup.path, filename), '/')}'"
                end
              end
              IO.select(still_open,nil,nil,nil)[0].each do |fh|
                begin
                  case fh
                  when stdout
                    need_log = false
                    if active
                      active = false
                      cnt, filename, size, md5 = @current
                      logfile.info "#{cnt} :: #{filename}"
                      dst = File.join(backup.static_path, filename)
                      if cnt.match(/deleting/)
                        if File.directory? dst
                          Dir.unlink dst
                        else
                          File.unlink dst
                        end
                        next          # FIXME this should be in a if or when
                      end
                      count = 0
                      src = File.join(backup.active_path, filename)
                      while !File.exists? src
                        break if File.symlink? src
                        sleep 0.01
                        if (count += 1) > 2
                          break
                        end
                        puts "FIXME #{src}"  
                      end
                      if count > 1000
                        logfile.info src
                        raise "failed to download #{src}"
                        next
                      end
                      if File.symlink? src
                        if File.exists?(dst) or File.symlink?(dst)
                          logfile.info "unlnked #{dst}" if @verbose
                          File.unlink dst
                        end
                        File.symlink( File.readlink(src), dst) 
                      else
                        case File.ftype(src)
                        when 'directory'
                          fdst = dst.sub(%r{/$}, '')
                          if !File.directory?(dst)
                            begin
                              if File.exist? fdst
                                File.unlink(fdst)
                              end
                              Dir.mkdir(dst, 0775)
                            rescue => x
                              logfile.info "error: #{x}"
                            end
                          end
                        when 'file'
                          begin
                            if File.exist?(backup.inode_path)
                              if md5.nil?
                                digest = Digest::MD5.new
                                File.open(src) do |file|
                                  digest << file.read
                                end
                                md5 = digest.to_s
                              end
                              if md5
                                dir = File.join(backup.inode_path, md5[0])
                                Dir.mkdir(dir) unless File.exists? dir
                                file = File.join(dir, md5)
                                if File.exists? file
                                  sstat =  File.stat(src)
                                  if File.stat(file).ino != sstat.ino
                                    File.utime(sstat.atime, sstat.mtime, file)
                                    File.chmod(sstat.mode, file)
                                    File.chown(sstat.uid, sstat.gid, file)
                                    fsstat =  File.stat(file)
puts "Fixup #{file} #{src}"
puts "m #{sstat.mode} #{fsstat.mode}" if sstat.mode != fsstat.mode
puts "u #{sstat.uid} #{fsstat.uid}" if sstat.uid != fsstat.uid
puts "g #{sstat.gid} #{fsstat.gid}" if sstat.gid != fsstat.gid
puts "a #{sstat.atime} #{fsstat.atime}" if sstat.atime != fsstat.atime
puts "m #{sstat.mtime} #{fsstat.mtime}" if sstat.mtime != fsstat.mtime
#puts "c #{sstat.ctime} #{fsstat.ctime}" if sstat.ctime != fsstat.ctime
                                    File.unlink(src)
                                    File.link(file, src)
                                  end
                                else
                                  File.link(src, file)
                                end
                              end
                            end
                            if File.exists?(dst)
                              if File.directory? dst
                                Dir.unlink(dst)
                                File.link(src, dst)
                              else
                                sstat = File.stat(src)
                                dstat = File.stat(dst)
                                if sstat.ino != dstat.ino
                                  File.rename(src, dst)    # NOTE: This causes the .static file to always be present
                                  File.link(dst, src)
                                end
                              end
                            else
                              path = File.dirname dst
                              unless File.exist? path
                                FileUtils.mkdir_p path
                              end
                              File.link(src, dst)
                            end
                          rescue => x
                            logfile.info "link error:: #{x}"
                            File.unlink(src)
                          end
                        else
                          raise "Error #{File.ftype(src).to_s}"
                        end
                      end
                      if @current
                        @current = nil
                      end
                    end
                    if line = stdout.readline
                      line.chomp!
                      logfile.info "'#{line}'" if @verbose
                      (cnt, filename, size, md5) = line.split(/\|/)
                      if md5.strip.size < 32
                        md5 = nil
                      end
                      size = size.to_i
                      if size.to_i > 2048 * 1
                        if File.exist?(backup.inode_path)
                          if md5
                            dir = File.join(backup.inode_path, md5[0])
                            file = File.join(dir, md5)
                            src = File.join(backup.active_path, filename)
                            if File.exists? file
                              sstat = File.stat(src)
                              fstat = File.stat(file)
                              if sstat.size != fstat.size
                                raise "#{sstat.size} #{fstat.size} #{src} #{file}"
                              end
                              # We need to send a signale to rsync here to get it to skip this file
                              #Process.kill("STOP", @pid)
                              #"COPY FILE #{file} #{src}"
                              #Process.kill("CONT", @pid)
                            end
                          end
                        end
                      end
                      start_time = Time.now
                      need_log   =  true
                      active     =  true  # 
                      @current = [cnt, filename, size, md5]
                    end
                    if @stop
                      if @pid
                        logfile.info "Stopping #{backup.name} #{@pid}"
                        begin
                          Process.kill 'TERM', @pid
                        rescue => x
                          logfile.error x
                        ensure
                          @pid = nil
                        end
                      end
                      raise EOFError
                    end
                  when stderr
                    if line = stderr.readline
                      line.chomp!
                      logfile.error "IO: #{line}"
                    end
                  end
                rescue EOFError => x
                  still_open.keep_if{ |x| x != fh }
                rescue => x
                  logfile.error "ERROR #{x}"
                end
              end # case
            end # while
            @exit_status = wait_thr.value
          end
        rescue => x
          logfile.error "Error End of Thread #{ @thread } #{x}"
        end
        @ended = Time.now
        @rthread = nil
        @stop = false
      end # Thread
      while @rthread
        @rthread.join(10)
        puts "check thread" if @rthread
      end
    end
  end # class Collector
end # module
__END__
