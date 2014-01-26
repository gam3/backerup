require 'set'

module BackerUp
  # This singleton contains all the Sources.
  # A source is a triple of host, path, source
  class Sources
    # Initialize the Sources singleton
    def initialize
      @pth = Hash.new { |h, k| h[k] = Hash.new }
      @src = Hash.new { |h, k| h[k] = Hash.new }
    end
    include Singleton
    # clear all the sources
    def clear
      @pth.clear
      @src.clear
    end
    # clear all the sources
    def self.clear
      instance.clear
    end
    # get the source for a given host, path, source
    def get(host, path, source)
      path = File.expand_path(path)
      if @pth[host][path] && @src[host][source]
        @src[host][source]
      elsif @pth[host][path] || @src[host][source]
        raise "Multiple sources for #{host}#{source}" unless @pth[host][path] == @src[host][source]
      else
        @src[host][source] = @pth[host][path] = Source.new(host, path, source)
      end
    end
    # get each path for a host
    def each_path(host = nil)
      hosts = host ? [ host ] : @pth.keys
      hosts.each do |host|
        @pth[host].each_key do |path|
	  yield path
	end
      end
    end
    # get each source for a host and path
    def get_source(host, path)
      source = nil
      @pth[host].keys.sort{ |a,b| b.size <=> a.size }.each do |match_path|
        next if path.size < match_path.size
	next unless match_path == path[0...match_path.size]
	source = @pth[host][match_path]
      end
      return source
    end
    # get the source for a given host, path, source
    def self.get(host, path, source)
      instance.get(host, path, source)
    end
  end
  # This singleton contains all the Backups.
  # A backup is a tuple of host, and path
  class Backups
    # Initialize
    def initialize
      @hash = Hash.new { |h, k| h[k] = Hash.new }
    end
    # return all the roots for all the backups
    def roots
      ret = Set.new
      @hash.each do |host, backup|
	backup.each do |path, data|
	  ret.add data.root
	end
      end
      ret.to_a
    end
    # return all the roots for all the backups
    def self.roots
      return instance.roots
    end
    include Singleton
    # clear the Backups 
    def clear
      @hash.clear
      Sources.clear
      Hosts.clear
    end
    # clear the Backups 
    def self.clear
      instance.clear
    end
    # get a particular backup
    def get(host, path)
      @hash[host][path] ||= BackerUp::Backup.new(host, path)
      @hash[host][path]
    end
    # get each path for a host or all hosts
    def each_path(host = nil)
      hosts = host ? [ host ] : @hash.keys
      hosts.each do |host|
        @hash[host].each_key do |path|
	  yield path
	end
      end
    end
    # get a backup
    def [](x, y)
      @hash[x][y] ||= Host::Backup.new(x, y)
      @hash[x][y]
    end
    # set a backup
    def []=(x, y)
      @hash[x][y] = z
    end
    # get all of the hosts
    def hosts
      @hash.keys
    end
    # get each backup
    def each(&b)
      @hash.each do |host, data|
        data.each do |path, backup|
          b.yield backup
	end
      end
    end
    # get each backup
    def self.each(&b)
      instance.each &b
    end
    # get all the roots
    def get_roots
      ret = Set.new
      @hash.each_key do |host|
        @hash[host].each do |path, backup|
	  ret.add backup.root
	end
      end
      ret.to_a
    end
    # get a backup
    def self.get(*e)
      instance.get(*e)
    end
  end
  # This singleton contains all the Host.
  class Hosts
    # Initialize
    def initialize
      @hash = Hash.new { |h, k| h[k] = Host.new(k) }
      @evals = []
    end
    include Singleton
    # clear the hosts
    def clear
      @hash.clear
      @evals.clear
    end
    # clear the hosts
    def self.clear
      instance.clear
    end
    # get a host
    def [](x)
      @hash[x]
    end
    # set a host
    def []=(x, y)
      @hash[x] = y
    end
    # get each host
    def each(&b)
      @hash.each_key do |key|
        b.yield key
      end
    end
  end
  # This singleton contains all or the Root Paths
  class Roots
    # Initialize
    def initialize
      @hash = Hash.new { |h, k| h[k] = Root.new(k) }
      @evals = []
    end
    include Singleton
    # clear the hosts
    def self.clear
      @hash.clear
    end
    # get a root
    def [](x)
      @hash[x]
    end
    # get the source for a given host, path, source
    def get(path)
      @hash[path]
    end
    # get the source for a given host, path, source
    def self.get(path)
      instance.get(path)
    end
    # get each root
    def each(&b)
      ret = self
      if b
	@hash.each_key do |key|
	  b.yield key
	end
      else
	ret = @hash.each_key.to_a
      end
      ret
    end
    # get each root
    def self.each(&b)
      instance.each &b
    end
  end
  # This class contains the Backup object that describes a
  # particular backup.  Except for the current available bandwidth
  # all information about a backup is contained in this object.
  class Backup
    # The host this backup refers to
    attr_reader :host
    # The path for the backup
    attr_reader :path
    # The root of the backup.  All other paths should be above this point and be on the same partition.
    attr_reader :root
    # The source for the rsync command
    attr_reader :source_path
    # Initialize the backup
    def initialize(hostname, path)
      @host = hostname
      @path = File.expand_path(path)
      @all_paths = []
      @exclude_paths = []
      @active_path = "/tmp/.active"
    end
    # to_s
    def to_s
       "backup: #{host} '#{path}' '#{source.to_s}'"
    end
    # add and exclude path to a backup
    def add_exclude(xlist)
      @exclude_paths << xlist
    end
    # set the defaults for a backup
    def set_defaults(d)
      @defaults = d
      d[:excludes] ||= Array.new
      d[:excludes].each do |path|
        @exclude_paths << path
      end
    end
    # Access to the logger
    def logfile
      BackerUp.logger
    end
    # get the bwlimit for a backup
    def bwlimit
      @bwlimit
    end
    # return the command to run
    def partial?
      true
    end
    def bwlimit
      '5000'
    end
    # get the root path for a backup
    def root
      '/opt/backerup'
    end
    # get the static path for a backup
    def partial_path
      File.join(self.root, '.partial', @host, @path)
    end
    # get the static path for a backup
    def active_path
      File.join(self.root, '.active', @host, @path)
    end
    # get the static path for a backup
    def static_path
      File.join(self.root, '.static', @host, @path)
    end
    # get the inode path for a backup
    def inode_path
      File.join(self.root, '.inodes')
    end
    # get the source
    def source
      source = Sources.instance.get_source(@host, @path)
      return nil unless source
      path = @path[source.path.size..-1]
      source.source + File.join(path, '.')
    end
    # Exclude all paths on this host that are children of our path 
    def exclude_paths
      our_path = File.expand_path(self.path)
      ret = []
#puts "FIX THIS"
      if @exclude_paths
	@exclude_paths.each do |path|
	  next unless path
	  exclude_path = path || ''
	  if exclude_path.match(/^#{our_path}\//)
	    exclude_path.sub!(/^#{@path}\//, '')
	  end
	  ret.push exclude_path
	end
      end

      Backups.instance.each_path(@host) do |exclude_path|
        next if @path == exclude_path
	if exclude_path.match(/^#{our_path}\//)
	  ret.push exclude_path.sub(/^#{@path}\//, '')
        end
      end
      return ret
    end

    # Generate the rsync command for the backup
    # @return [Array] the arguments list
    def command
      ret = []
      ret.push 'rsync'
#      ret.push '/home/gam3/src/rsync/rsync'
      ret.push '--archive'
      ret.push '--update'
      ret.push '--out-format=%i|%n|%l|%C'
      ret.push '--delete'
      if self.partial? && (partial_path = self.partial_path)
	ret.push '--partial'
	ret.push "--partial-dir=#{partial_path}"
      end
      if limit = self.bwlimit
	ret.push "--bwlimit=#{limit}"
      end
      self.exclude_paths.each do |exclude|
	ret.push "--exclude=#{exclude}"
      end
      return [] unless self.source		# FIXME  This should not be here at all
      ret.push self.source
      ret.push self.active_path
#        logfile.debug(ret.join(' '))
      ret
    end
  end
  # The Source class describes how to get a backup over the network.
  class Source
    # the host
    attr_reader :host
    # the path of the source
    attr_reader :path
    # Initialize
    def initialize(host, path, source)
      @host = host
      @path = File.expand_path(path)
      @source = source
    end
    # set defaults
    def set_defaults(defaults)
      @defaults = defaults
    end
    # get the source string
    def source
      if @source[0] == ':'
        @host + @source
      else
        @source
      end
    end
  end
  # The Host class holds information for a given device
  class Host
    # the name of the host
    attr_reader :name
    # Initialize
    def initialize(host)
      @name = host
    end
  end
  # The Root class holds information for a given root
  class Root
    # the path to the root
    attr_reader :path
    # initialize
    def initialize(root_path)
      @path = root_path
    end
  end
end
