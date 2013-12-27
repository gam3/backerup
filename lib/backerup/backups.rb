require 'set'

module BackerUp
  # This singleton contains all the Sources.
  # A source is a triple of host, path, source
  class Sources
    def initialize
      @pth = Hash.new { |h, k| h[k] = Hash.new }
      @src = Hash.new { |h, k| h[k] = Hash.new }
    end
    include Singleton
    def get(host, path, source)
      path = File.expand_path(path)
      if @pth[host][path] || @src[host][source]
        raise "Multiple sources for #{host}#{source}" unless @pth[host][path] == @src[host][source]
      else
        @src[host][source] = @pth[host][path] = Source.new(host, path, source)
      end
    end
    def each_path(host = nil)
      hosts = host ? [ host ] : @pth.keys
      hosts.each do |host|
        @pth[host].each_key do |path|
	  yield path
	end
      end
    end
    def get_source(host, path)
      source = nil
      @pth[host].keys.sort{ |a,b| b.size <=> a.size }.each do |match_path|
        next if path.size < match_path.size
	next unless match_path == path[0...match_path.size]
	source = @pth[host][match_path]
      end
      return source
    end
  end
  # This singleton contains all the Backups.
  # A backup is a tuple of host, and path
  class Backups
    def initialize
      @hash = Hash.new { |h, k| h[k] = Hash.new }
    end
    def configure(x, y)
raise "#{self} # configure"
      @hash[x][y] ||= BackerUp::Backup.new(x, y)
      @hash[x][y].configure
    end
    include Singleton
    def get(x, y)
      @hash[x][y] ||= BackerUp::Backup.new(x, y)
      @hash[x][y]
    end
    def each_path(host = nil)
      hosts = host ? [ host ] : @hash.keys
      hosts.each do |host|
        @hash[host].each_key do |path|
	  yield path
	end
      end
    end
    def [](x, y)
      @hash[x][y] ||= Host::Backup.new(x, y)
      @hash[x][y]
    end
    def []=(x, y)
      @hash[x][y] = z
    end
    def hosts
      @hash.keys
    end
    def each(&b)
      @hash.each do |host, data|
        data.each do |path, backup|
          b.yield backup
	end
      end
    end
    def get_roots
      ret = Set.new
      @hash.each_key do |host|
        @hash[host].each do |path, backup|
	  ret.add backup.root
	end
      end
      ret.to_a
    end
  end
  # This singleton contains all the Host.
  class Hosts
    def initialize
      @hash = Hash.new { |h, k| h[k] = Host.new(k) }
      @evals = []
    end
    include Singleton
    def [](x)
      @hash[x]
    end
    def []=(x, y)
      @hash[x] = y
    end
    def each(&b)
      @hash.each_key do |key|
        b.yield key
      end
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
    def add_exclude(xlist)
      @exclude_paths << xlist
    end
    def set_defaults(d)
      @defaults = d
      @exclude_paths << d[:excludes]
    end
    # Access to the logger
    def logfile
      BackerUp.logger
    end
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
    def root
      '/opt/backerup'
    end
    def partial_path
      File.join(self.root, '.partial', @host, @path)
    end
    def active_path
      File.join(self.root, '.active', @host, @path)
    end
    def static_path
      File.join(self.root, '.static', @host, @path)
    end
    def inode_path
      File.join(self.root, '.inodes', @host, @path)
    end
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
    # @returns Array the arguments list
    def command
      ret = []
      ret.push 'rsync'
      ret.push '-a'
      ret.push '--out-format=%i|%n'
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
    attr_reader :host
    attr_reader :path
    def initialize(a, path, c)
      @host = a
      @path = File.expand_path(path)
      @source = c
    end
    def set_defaults(defaults)
      @defaults = defaults
    end
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
  end
end
