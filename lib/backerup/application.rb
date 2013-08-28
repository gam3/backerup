require 'pp'
require 'logger'

require 'optparse'
require 'ostruct'
require 'backerup/version'
require 'backerup/configure'
require 'backerup/collector'
require 'backerup/backups'
require 'shellwords'

module BackerUp
  module Logger
    class Logger < ::Logger
    end
  end
  class <<self
    attr_accessor :logger
  end
  class Application
    LOGFILE_NAME = '/var/log/backerup.log'
    CONFFILE_NAME = '/etc/backerup.conf'

    attr_reader :original_dir

    def initialize
      @original_dir = Dir.getwd 
      @options = OpenStruct.new
    end

    def read_configuration(filename)
      configureation = Configure.new
      File.open(filename, 'r') do |file|
        data = file.read
        configureation.instance_eval data
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

      BackerUp.logger = Logger::Logger.new(options.logfile_name)

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
        STDERR.puts "Could not read configuration file '#{options.conf_name}', it has unknown variables"
        STDERR.puts x.to_s.gsub('(eval)', "(#{options.conf_name})" )
      rescue => x
        puts x.inspect
      end

      if @configuration.nil?
        exit(1)
      end

      backups = BackerUp::Backups.new(@configuration)

      logfile.debug "Starting backerup"

      all  = Array.new

      backups.each do |backup|
        all.push BackerUp::Collector.new(backup)
      end

      if options.dryrun
        backups.each do |backup|
          puts backup.command.map{ |x| Shellwords.escape(x) }.join(' ')
        end
        exit(0)
      end
      collect = []
      while true
        all.each do |c|
          if c.due?
            puts c
            t = c.trun
            logfile.info "Started #{ t }"
          end
        end
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
      @application ||= BackerUp::Application.new
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

