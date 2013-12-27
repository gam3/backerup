require 'pp'

require 'optparse'
require 'ostruct'
require 'backerup/version'
require 'backerup/configure'
require 'backerup/collector'
require 'backerup/backups'
require 'backerup/logger'
require 'shellwords'
require 'inotify'
require 'date'

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

    def initialize
      @original_dir = Dir.getwd 
      @options = OpenStruct.new
      case File.basename($0)
      when 'backerup'
        options.app = 'backup'
      when 'backerup-clean'
        options.app = 'clean'
      when 'backerup-copy'
        options.app = 'copy'
      end
    end

    def read_configuration(filename)
      configureation = Configure.new()
      File.open(filename, 'r') do |file|
        data = file.read
        configureation.top(data, filename)
      end
      configureation
    end

    def logfile
      BackerUp.logger
    end

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
      when 'backup'
        backup
      when 'clean'
        clean
      when 'copy'
        copy
      end
    end

    def clean
      logfile.info "Starting backerup cleaner"
      logfile.info DateTime.now.strftime()
      roots = Backups.instance.get_roots
      BackerUp::AppCleaner.new(roots).run
    end

    def copy
      logfile.debug "Starting backerup copy"
      puts DateTime.now.strftime("%Y%m%d%H%M%S")
pp @configuration
      BackerUp::AppCopier.new
    end

    def backup
      backups = Backups.instance

      logfile.debug "Starting backerup"

      all  = Array.new

      at_exit do
        all.each do |c|
	  if c.pid
	    Process.kill("TERM", c.pid)
	  end
	end
	exit
      end

      if options.dryrun
        backups.each do |backup|
          puts backup.command.map{ |x| Shellwords.escape(x) }.join(' ')
        end
        exit(0)
      end

      change = false

      backups.each do |backup|
        all.push Collector.new(backup)
      end

      while true
        all.each do |c|
          if c.due?
            t = c.trun
            logfile.info "Started #{ t }"
            change = true
          end
        end
        if change
          all.each do |c|
puts "Change #{c}"
          end
        end
	change = false
        sleep 10
      end
    end

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

