
require 'optparse'
require 'ostruct'
require 'backerup/version'

module BackerUp
  class Application
    def run(*args)
      @name = $0
      handle_options
    end

    def options
      @options ||= OpenStruct.new
    end

    # A list of all the standard options used by backerup
    def standard_options
      [
        [ '--conf', '-c',
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
        opts.environment('BAKERUP_OPT')
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

