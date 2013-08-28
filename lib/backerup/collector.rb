
require 'fileutils'
require 'open3'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  class Collector
    attr_reader :thread
    attr_reader :current
    def initialize(config)
      @config = config
      @verbose = false
      @started = nil
    end
    # is the collector due to run
    def due?
      if @thread
        return false
      end
      if @ended
        if Time.now - @ended  < 1800
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
    def run
      if @thread
        return nil
      end
      thread = trun
      thread.join if thread
      @thread = nil
    end
    def stop
      @stop = true
    end
    def kill
      Process.kill 'TERM', @pid
      @pid = nil
    end
    # run the collector in asyncronous mode
    def trun
      backup = @config

      begin
        FileUtils.mkdir_p( backup.active_path, :mode => 0755 )
        FileUtils.mkdir_p( backup.static_path, :mode => 0755 )
      rescue => x
        logfile.error "unable to create directory #{x}"
        return
      end

      raise "You can't run the collector twice" if @thread

      @started = Time.now
      @thread = Thread.new do
        begin
          Open3.popen3(*backup.command) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            still_open = [stdout,stderr]
            @pid = wait_thr.pid
            while not still_open.empty?
              IO.select(still_open,nil,nil,nil)[0].each do |fh|
                begin
                  case fh
                  when stdout
                    if @current
                      cnt, filename = @current
                      @current = nil
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
                            if File.exists?(dst)
                              if File.directory? dst
                                Dir.unlink(dst)
                                File.link(src, dst)
                              else
                                File.rename(src, dst)    # NOTE: This causes the .static file to always be present
                                File.link(dst, src)
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
                      (cnt, filename) = line.split(/\|/)
                      logfile.debug "starting: '#{File.absolute_path(File.join(backup.path, filename), '/')}'"
                      @current = [cnt, filename]
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
        logfile.info "End of Thread #{ @thread }"
        @ended = Time.now
        @thread = nil
        @stop = false
      end # Thread
    end # def run
  end # class Collector
end # module
