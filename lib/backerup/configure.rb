#require 'pp'

require 'resolv'
require 'socket'
require 'singleton'
require 'backerup/backups'

module BackerUp
  class Source
    def configure
      @configure ||= Configure::Source.new(@host, @path, @source)
    end
  end
  class Backup
    def configure
      @configure ||= Configure::Backup.new(@host, @path)
    end
  end
  class Host
    def configure
      @configure ||= Configure::Host.new(@host)
    end
  end
  # Get the hostname of the computer we are running on
  class Hostname
    include Singleton
    def self.hostname
      unless @hostname
        @hostname = Socket.gethostname
      end
      @hostname
    end
  end
end

module BackerUp
  # The configuration files are executed under this class
  class Configure
    # This class is used to disable sections of configuation file
    class Skip < Exception; end
    # This module holds the mixins for the confituraion classes.
    module Common
      # Skip the current configuration section
      def skip msg = nil, bt = caller
	@skip = [ msg, bt ]
	raise Skip, msg, bt
      end
      # Set the root of the backup
      def root(path)
        @set[:root] = path
      end
      # Set the maximum bandwidth for this backup
      def bandwidth(name)
	puts "bandwidth changed #{@bandwidth} -> #{name} in group #{@name}" if @bandwidth
	@bandwidth = name
      end
      # Make configurations specific to the host we are running on
      def hostname(name, &block)
	hostname = Hostname.hostname
	raise "no #{hostname} : #{name}" unless hostname and name
	if hostname.downcase == name.downcase
	  if block
	    self.instance_eval &block
	  end
	  true
	else
	  @skipped_hostsnames.push name
	  false
	end
      end
      def network(x)
	@n = x
      end
      def network=(x)
	@n = x
      end
    end
    # Configure a single backup
    class Backup
      def initialize(host, path, defaults = {})
        @path = path
        @host = host
        puts "no host for #{@path}" unless @host
        @excludes = Array.new
        @eval = []
        @set = {}
	@defaults = defaults
      end
      include Common
      # Create or update the backup
      def expand
        backup = Backups.instance.get(@host, @path)
	backup.set_defaults @defaults
      end
      # Add a source for a particular backup, this
      # @return [Configure::Source] The Source object
      # source must have the same path as the backup it is described in.
      #   backup('bob', '/etc') { source('::etc') }
      # is the same as
      #   backup('bob', '/etc')
      #   source('bob', '/etc', '::etc')
      def source(source, &block)
        config = Configure::Source.new(@host, @path, source, @defaults)
	if block
	  config.instance_eval &block
	end
	Sources.instance.get(@host, @path, source).set_defaults(config.values)
# FIXME excludes
      end
      def exclude(path)
        if (path[0] == '/') 
          full_path = File.expand_path(path)
        else
          full_path = File.join(@path, path)
	end
        @excludes.push full_path
      end
    end
    # Configure a single source
    class Source
      def initialize(host, path, source_path, defaults = {})
        @host = host
	@path = path
	@source = source_path
	@defaults = defaults
	@set = {}
      end
      def values
        @defaults.merge @set
      end
      def bandwidth(bw)
        @set[:bandwidth] = bw
      end
      # Create or update the source
      def expand
        source = Sources.instance.get(@host, @path, @source)
      end
    end
    # Configure a single host
    class Host
      def initialize(host, defaults = {})
puts "HOST"
        @host = host
	@defaults = defaults
      end
    end
    def initialize
      @defaults = {
        :root => '/opt/backerup',
        :active_name => '.active',
        :static_name => '.static',
        :partial_name => '.partial',
        :inode_name => '.inodes',
      }
    end
    def top(data, filename, line = 1)
      raise "There can be only one top group" if @top
      @top = {
        :root => '/opt/backerup/xxx',
        :active_name => '.active',
        :static_name => '.static',
        :partial_name => '.partial',
        :inode_name => '.inodes',
	:bandwidth => '5000',
      }
      group = Configure::Group.new(@top)
      begin
        group.instance_eval data, filename, line
      rescue
        puts group
        puts caller
        raise
      end
      group.expand()
    end
    # This class is similar to a Group, but describes backups and sources for a 
    # particular host.
    class HostGroup
      include Common
      def initialize(hostname, defaults = {})
	@hostname = hostname
	@defaults = defaults
	@eval = Array.new
	@excludes = Array.new
        @skipped_hostsnames = []
	@set = Hash.new
	@set[:excludes] = Array.new
      end
      # expand the hostgroup
      def expand()
        new_defaults = @defaults.merge(@set)
	@excludes.each do |e|
	  new_defaults[:excludes] << e
	end
        @eval.each do |e|
	  case e[0]
	  when :backup
	    obj = Backup.new(e[1], e[2], new_defaults)
	  when :source
	    obj = Source.new(e[1], e[2], e[3], new_defaults)
	  when :group
	    obj = HostGroup.new(@hostname, new_defaults)
	  else
raise e[0].to_s
	  end
	  if e[-1]
	    obj.instance_eval &(e[-1])
	  end
	  obj.expand
	end
	@eval.clear
      end
      def backup(path, &block)
        host = @hostname
        path = File.expand_path(File.join('/', path))
        begin
	  if block
	    @eval.push [:backup, host, path, block]
	  else
	    @eval.push [:backup, host, path, nil]
	  end
	rescue => x
	  puts "Backup  #{x}"
	  puts caller
	  puts x
	end
      end
      def source(base_path, source_path, &block)
        host = @hostname
	if block
	  @eval.push [:source, host, base_path, source_path, block]
	else
	  @eval.push [:source, host, base_path, source_path, nil]
	end
      end
      def exclude(path)
        @excludes.push path
      end
      def group(name = :default, &block)
	if block
	  @eval.push [:group, name, block]
	else
	  puts "A group without a block is not very helpful"
	end
      end
    end
    # The Group class is used to group hosts, backups and sources
    class Group
      include Common
      def initialize(defaults = {})
	@eval = []
	@defaults = defaults
	@set = Hash.new
        @skipped_hostsnames = []
      end
      def expand()
        new_defaults = @defaults.merge(@set)
        @eval.each do |e|
	  obj = nil
          case e[0]
	  when :group
	    obj = Group.new(new_defaults)
	  when :host
	    obj = HostGroup.new(e[1], new_defaults)
	  else
puts "FIXME #{e}"
          end
	  if obj
	    if e[2]
	      obj.instance_eval &e[2] 
	    end
	    obj.expand()
          end
	end
      end
      def backup(hostname, path, &block)
	if block
	  @eval.push [:backup, hostname, path, block]
	else
	  @eval.push [:backup, hostname, path, nil ]
	end
	return self
      end
      # Add a source using the group defaults
      def source(host, base_path, source_path, &block)
	if block
	  @eval.push [:source, host, base_path, source_path, block]
	else
	  @eval.push [:source, host, base_path, source_path, nil ]
	end
	self
      end
      def host(name, &block)
	if block
	  @eval.push [:host, name, block]
	else
	  puts "A host (#{name}) without a block is not very helpful"
	end
      end
      def group(name = :default, &block)
	if block
	  @eval.push [:group, name, block]
	else
	  puts "A group without a block is not very helpful"
	end
      end
    end
  end
  # This class contains configuration section common to all sections
end
