
require 'fileutils'
require 'open3'

require 'backerup/configure'
configure = BackerUp::Configure.new

module BackerUp
  # This class contains the collector application of backerup system
  class AppCopier
    # run the copier application
    def run
      puts "COPY"
    end # def run
  end # class Collector
end # module
