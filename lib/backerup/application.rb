require 'pp'
require 'logger'

require 'optparse'
require 'ostruct'
require 'backerup/version'
require 'backerup/configure'
require 'backerup/collector'

module BackerUp
  module Logger
    class Logger < ::Logger
    end
  end
  class Application
    def initialize
      @original_dir = Dir.getwd 
      @logger = Logger::Logger.new(STDOUT)
    end
    attr_reader :original_dir
    def read_configuration(filenames)
      filenames.each do |filename|
        if File.exists?(filename)
          @configureation = Configure.new
          File.open(filename, 'r') do |file|
            data = file.read
            @configureation.instance_eval data
          end
        end
      end
    end

    def logfile
      @log ||= Logger::Logger.new('/tmp/logger')
    end

    def run(*args)
      @name = $0
      @configure ||= Array.new
      handle_options
      if @configure.size == 0
        @configure.push '/etc/backerup.conf'
      end
      read_configuration @configure
      if @configureation.nil?
        puts "No configuration file found"
        exit
      end
      backups = BackerUp::Configure::Backups.new(@configureation)
      all  = Array.new
      backups.each do |backup|
        all.push BackerUp::Collector.new(backup)
      end
      collect = []
      while true
        all.each do |c|
          if c.due?
            puts c
            t = c.trun
            logfile.info "Started #{ t }"
          end
          if c.thread
#            logfile.info "active #{c.thread}"
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
        [ '--conf', '-c filename',
          "Path to configuration file",
          lambda { |value|
            @configure.push value
          }
        ],
        [ '--dry-run', '-n',
          "Do a dry run without executing actions.",
          lambda { |value|
#            BackerUp.verbose(true)
#            BackerUp.nowrite(true)
            options.dryrun = true
            options.trace = true
          }
        ],
        [ '--version', '-V',
          "Display version and exit",
          lambda { |value|
            puts "#{@name} version #{VERSION}"
            exit
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
          exit
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

