
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
    def due?
      if @thread
        return false
      end
      if @ended
        puts Time.now - @ended 
        if Time.now - @ended  < 3600
          return false
        end
      end
      return true
    end
    def logfile
      @log ||= Logger::Logger.new('/tmp/logger')
    end
    def run
      if @thread
        return nil
      end
      thread = trun
puts "wait"
      thread.join if thread
puts "done"
      @thread = nil
    end
    def trun
      backup = @config

      begin
        FileUtils.mkdir_p( backup.active_path, :mode => 0755 )
        FileUtils.mkdir_p( backup.static_path, :mode => 0755 )
      rescue => x
        log.error "unable to create directory #{x}"
        return
      end

      raise "You can't run the collector twice" if @thread

      @started = Time.now
      @thread = Thread.new do
        begin
          Open3.popen3(*backup.command) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            still_open = [stdout,stderr]
            control = []
            while not still_open.empty?
              IO.select(still_open,nil,nil,nil)[0].each do |fh|
                begin
                  case fh
                  when stdout
                    if control.size > 0
                      cnt, filename = control.shift
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
                        puts "FIXME #{src}"  
                        sleep 0.01
                        if (count += 1) > 1000
                          break
                        end
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
                      control.push [cnt, filename]
                      logfile.info "set '#{line}'"
                      @current = [cnt, filename]
                    end
                  when stderr
                    if line = stderr.readline
                      logfile.error "IO: #{line}"
                    end
                  end
                rescue EOFError => x
                  still_open.keep_if{ |x| x != fh }
                rescue => x
                  logfile.error "ERROR #{x}"
puts x.inspect
                end
              end # case
            end # while
            logfile.info 'bob' until wait_thr.join(0.15)
          end
        rescue => x
          logfile.error "Error End of Thread #{ @thread } #{x}"
        end
        logfile.info "End of Thread #{ @thread }"
        @ended = Time.now
        @thread = nil
      end # Thread
    end # def run
  end # class Collector
end # module
