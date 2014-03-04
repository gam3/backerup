# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'optparse'
require 'ostruct'
require 'backerup/version'
require 'backerup/configure'
require 'backerup/backups'
require 'backerup/logger'
require 'shellwords'
require 'inotify'
require 'date'

begin
  require 'ffi'
   
  module LinuxProcName
    # Set process name
    PR_SET_NAME = 15
   
    module LibC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC
   
      begin
	attach_function :prctl, [ :ulong, :ulong, :ulong, :ulong ], :int
      rescue FFI::NotFoundError
	# We couldn't find the method
      end
    end
   
    def self.set_proc_name(name)
      return false unless LibC.respond_to?(:prctl)
   
      # The name can be up to 16 bytes long, and should be null-terminated if
      # it contains fewer bytes.
      name = name.slice(0, 16)
      ptr = FFI::MemoryPointer.from_string(name)
      LibC.prctl(PR_SET_NAME, ptr.address, 0, 0)
    ensure
      ptr.free if ptr
    end
  end
rescue
  module LinuxProcName
    def self.set_proc_name(name)
    end
  end
end

require 'backerup/cleaner'

module BackerUp
  # This class holds the different applications of the backerup system
  class AppCollector
    # This is the default location of the log file
    LOGFILE_NAME = '/var/log/backerup.log'
    # This is the default location of the configuration file 
    CONFFILE_NAME = '/etc/backerup.conf'

    # The location where BackerUp was run from
    attr_reader :original_dir
    # initialize 
    def initialize
      LinuxProcName.set_proc_name($0)
      @original_dir = Dir.getwd 
      @options = OpenStruct.new
      case File.basename($0)
      when 'backerup'
        options.app = 'daemon'
      when 'backerup-collector'
        options.app = 'backup'
      when 'backerup-clean'
        options.app = 'clean'
      when 'backerup-copy'
        options.app = 'copy'
      end
    end

    # get the configuration
    def read_configuration(filename)
      configureation = Configure.new()
      File.open(filename, 'r') do |file|
        data = file.read
        configureation.top(data, filename)
      end
      configureation
    end

    # get the logfile
    def logfile
      BackerUp.logger
    end

    # run
    def run(*args)
      @name = $0
      @configure ||= Array.new
      handle_options
      options.logfile_name = LOGFILE_NAME unless options.logfile_name
      options.conf_name = CONFFILE_NAME unless options.conf_name

      # rotate the log files
      if options.logfile_name
        BackerUp.logger = Logger::Logger.new(options.logfile_name)
	BackerUp.logger.level = Logger::Logger::DEBUG

        i = Inotify.new

        t = Thread.new do
          i.each_event do |ev|
             if ev.name == File.basename(options.logfile_name)
               logfile.error("Logfile rotation #{options.logfile_name}")
               logfile.close()
               BackerUp.logger = Logger::Logger.new(options.logfile_name)
               logfile.info("Recreated #{options.logfile_name}")
             end
          end
        end
        if options.logfile_name.class == String
          dirname = File.dirname(options.logfile_name)

          i.add_watch(dirname, Inotify::DELETE | Inotify::MOVE)
        end
      end

      begin
        @configuration = read_configuration options.conf_name
      rescue Errno::ENOENT => x
        STDERR.puts "Could not read configuration file '#{options.conf_name}',it does not exist"
      rescue Errno::EISDIR => x
        STDERR.puts "Could not read configuration file '#{options.conf_name}', it is a Directory"
      rescue SyntaxError => x
        STDERR.puts "Could not read configuration file '#{options.conf_name}', it has syntax errors"
        STDERR.puts x.to_s.gsub('(eval)', "(#{options.conf_name})" )
      rescue NameError => x
        STDERR.puts "#{x.inspect}"
        STDERR.puts "Could not read configuration file '#{options.conf_name}', it has unknown variables"
        raise x
        STDERR.puts x.to_s.gsub('(eval)', "(#{options.conf_name})" )
      rescue => x
        puts x.inspect
      end

      if @configuration.nil?
        exit(1)
      end
      if options.show_configuration
	puts 'configuration:'
        pp @configuration.to_string
        exit(0)
      end

      case options.app
      when 'daemon'
        daemon
      when 'backup'
        backup
      when 'clean'
        clean
      when 'copy'
        copy
      end

      logfile.info "Stopping backerup service"
    end

    # clean once
    def clean
      require 'backerup/cleaner'
      logfile.info "Starting backerup cleaner"
      Roots.each do |root|
	BackerUp::AppCleaner.run(root, :dryrun => options.dryrun, :verbose => options.verbose)
      end
    end

    # copy once
    def copy
      require 'backerup/copier'
      logfile.debug "Starting backerup copy"
      Roots.each do |root|
	if options.dryrun
	  BackerUp::AppCopier.dry_run(root)
	else
	  BackerUp::AppCopier.run(root)
	end
      end
    end

    # collect once
    def backup
      require 'backerup/collector'
      logfile.debug "Starting backerup backup"
      Backups.each do |backup|
        if options.dryrun
          BackerUp::AppCollector.dry_run(backup)
        else
          BackerUp::AppCollector.run(backup)
        end
      end
    end

    # run as a daemon
    def daemon
      require 'backerup/collector'
      require 'backerup/cleaner'
      require 'backerup/copier'

      @threads = []

      logfile.info "Starting backerup service"

      Signal.trap("INT") do
	puts "INT II"
	exit(1)
      end
      Signal.trap("QUIT") do
	puts "QUIT II"
	exit(1)
      end
      Signal.trap("TERM") do
	puts "TERM II"
	exit(1)
      end

      at_exit do
        @threads.each do |c|
	  begin
	    c.stop
	  rescue => x
	    logfile.debug "error in exit #{x} #{c}"
	  end
        end
        logfile.info "Stopped backerup cleaner"
      end
      if options.dryrun
        Roots.each do |root|
	  puts "copy #{root}"
	  puts "clean #{root}"
	end
        Backups.each do |backup|
	  puts "collect from #{backup}"
	end
      else
        Roots.each do |root|
          @threads.push BackerUp::AppCleaner.trun(root)
          @threads.push BackerUp::AppCopier.trun(root)
	end
        Backups.each do |backup|
          @threads.push BackerUp::AppCollector.trun(backup)
	end
	while @threads
	  sleep 60
	end
      end
    end
    # get options
    def options
      @options ||= OpenStruct.new
    end

    # A list of all the standard options used by backerup
    def standard_options
      [
        [ '--config', '-c filename',
          "Path to configuration file",
          lambda { |value|
            options.conf_name = value
          }
        ],
        [ '--dry-run', '-n',
          "Do a dry run without executing actions",
          lambda { |value|
            options.dryrun = true
            options.trace = true
            options.logfile_name = STDERR
          }
        ],
        [ '--show-configuration', '-C',
          "Display the configuration information",
          lambda { |value|
            options.show_configuration = true
            options.logfile_name = STDERR
          }
        ],
        [ '--debug', '-D',
          "Debug",
          lambda { |value|
            options.logfile_name = STDERR
            options.logfile_level = Logger::Logger::DEBUG
          }
        ],
        [ '--log-file=', '-l',
          "log what we're doing to the specified FILE",
          lambda { |value|
            options.logfile_name = value
          }
        ],
        [ '--verbose', '-v',
          "ncrease verbosity",
          lambda { |value|
            options.verbose = true
          }
        ],
        [ '--version', '-V',
          "Display version and exit",
          lambda { |value|
            puts "#{@name} version #{VERSION}"
            exit(0)
          }
        ],
        [ '--clean',
          "Run the cleaner",
          lambda { |value|
            options.app = 'clean'
          }
        ],
        [ '--copy',
          "Run the copier",
          lambda { |value|
            options.app = 'copy'
          }
        ],
        [ '--backup',
          "Run the backerup process",
          lambda { |value|
            options.app = 'backup'
          }
        ],
        [ '--daemon',
          "Run the backerup process",
          lambda { |value|
            options.app = 'daemon'
          }
        ],
      ]
    end

    # Read and handle the command line options.
    def handle_options
      OptionParser.new do |opts|
        opts.banner = "#{@name} [-f rakefile] {options} targets..."
        opts.separator ""
        opts.separator "Options are ..."
        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit(0)
        end
        standard_options.each { |args| opts.on(*args) }
        opts.environment('BACKERUP_OPT')
      end.parse!
    end
  end
  class << self
    # Current BarkerUp Application
    def application
      @application ||= BackerUp::AppCollector.new
    end

    # Set the current BackerUp application object.
    def application=(app)
      @application = app
    end

    # Return the original directory where the BackerUp application was started.
    def original_dir
      application.original_dir
    end

    # Load a configuration file.
    def load_config(path)
      load(path)
    end
  end
end

