
require 'fileutils'
require 'open3'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  class Collector
    def initialize(config)
      @config = config
      @verbose = false
    end
    def logfile
      @log ||= Logger::Logger.new('/tmp/logger')
    end
    def run
      backup = @config

      begin
        FileUtils.mkdir_p( backup.active_path, :mode => 0755 )
        FileUtils.mkdir_p( backup.static_path, :mode => 0755 )
      rescue => x
        log.error "unable to create directory #{x}"
        return
      end

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
#                  raise "FIXME #{src}"  
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
                      unless File.exists? Dir.directory dst
puts "missing Directory #{Dir.directory dst}"
                        FileUtils.mkdir_p( Dir.directory(dst), :mode => 0755 )
                      end
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
                    rescue Errno::ENOENT => x
                      File.unlink(src)
                    rescue => x
                      logfile.info "link error:: #{x}"
                      File.unlink(src)
                    end
                  else
                    raise "Error #{File.ftype(src).to_s}"
                  end
                end
                next
                if filename.match(%r|/$|)
                  src = File.join(backup.active_path, filename)
                  dst = File.join(backup.static_path, filename)
                  begin
                    Dir.mkdir(dst, 0775)
                  rescue => x
                    logfile.info "error #{x}"
                  end
                else
                  src = File.join(backup.active_path, filename)
                  dst = File.join(backup.static_path, filename)
                  if  File.symlink? src
                    File.symlink( File.readlink(src), dst) 
                    next  # FIXME
                  end
                  while !File.exists? src
                    logfile.info "wait #{src}"
                    sleep 0.1
                  end
                  begin
                    File.link(src, dst)
                  rescue => x
                    logfile.info "link error: #{x}"
                  end
                end
              end
              if line = stdout.readline
                line.chomp!
                logfile.info "'#{line}'" if @verbose
                (cnt, filename) = line.split(/\|/)
                control.push [cnt, filename]
              end
            when stderr
              if line = stderr.readline
                logfile.info "Error: #{line}"
              end
            end
          rescue EOFError => x
            still_open.keep_if{ |x| x != fh }
          rescue => x
            logfile.info "ERROR #{x}"
          end
          end # case
        end # while
        logfile.info 'bob' until wait_thr.join(0.15)
      end
    end # def run
  end # class Collector
end # module
