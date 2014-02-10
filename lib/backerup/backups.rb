# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'set'
require 'backerup/backup'

module BackerUp
  # @api public
  # This singleton contains all the Sources.
  # A source is a triple of host, path, source
  # For a given host path pair there can only be a single source and 
  # for any host source pair there can be only on source.
  class Sources
    # @api private
    # Initialize the Sources singleton
    def initialize
      @pth = Hash.new { |h, k| h[k] = Hash.new }
      @src = Hash.new { |h, k| h[k] = Hash.new }
    end
    include Singleton

    # clear all the sources
    # @return [Array] The list of sources removed
    def clear
      ret = @src.values
      @pth.clear
      @src.clear
      ret
    end
    # clear all the sources
    # @return [Array] The list of sources removed
    # @example BackerUp::Sources.clear
    def self.clear
      instance.clear
    end

    # get the number of sources
    # @return [Fixnum] The number of 'Source's defined
    def self.size
      instance.size
    end
    # get the number of sources
    # @return [Fixnum] The number of 'Source's defined
    def size
      @src.size
    end

    # get the Source for a given host, path, source
    # @return [Source] the object described by the host and source_path
    def self.get(host, path, source)
      instance.get(host, path, source)
    end
    # get the Source for a given host, path, source
    # @raise [ArgumentError] if the the source would be redefined
    def get(host, path, source)
      path = File.expand_path(path)
      if @pth[host][path] && @src[host][source]
        @src[host][source]
      elsif @pth[host][path] || @src[host][source]
        raise ArgumentError.new("Multiple sources for #{host}#{source}") unless @pth[host][path] == @src[host][source]
      else
        @src[host][source] = @pth[host][path] = Source.new(host, path, source)
      end
    end

    # get the Source for a given host, path
    def get_source(host, path)
      source = nil
      @pth[host].keys.sort{ |a,b| b.size <=> a.size }.each do |match_path|
        next if path.size < match_path.size
        next unless match_path == path[0...match_path.size]
        source = @pth[host][match_path]
        break;
      end
      return source
    end
    # get the Source for a given host, path
    # @return [Source] the object described by the host and path
    def self.get_source(host, path)
      instance.get_source( host, path )
    end

    # get each path for a host
    def each_path(host = nil)
      hosts = host ? [ host ] : @pth.keys
      hosts.each do |host|
        if @pth.include? host
          @pth[host].each_key do |path|
            yield path
          end
        end
      end
    end
  end
  # This singleton contains all the Backups.
  # A backup is a tuple of host, and path
  class Backups
    # Initialize
    def initialize
      @hash = Hash.new { |h, k| h[k] = Hash.new }
    end
    include Singleton

    # clear the Backups 
    def self.clear
      instance.clear
    end
    # the number of backups defined
    def self.size
      instance.size
    end
    # get each backup
    def self.each(&b)
      instance.each &b
    end
    def self.get(host, path)
      instance.get(host, path)
    end
    # get a backup
    def self.get(*e)
      instance.get(*e)
    end

    # clear the Backups 
    def clear
      @hash.clear
      Sources.clear
      Hosts.clear
    end
    def size
      @hash.size
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
        if @hash.include? host
          @hash[host].each_key do |path|
            yield path
          end
        end
      end
    end
    # get each backup
    def each(&b)
      @hash.each do |host, data|
        data.each do |path, backup|
          b.yield backup
        end
      end
    end
  end
  # This singleton contains all the Host.
  class Hosts
    # Initialize
    def initialize
      @hash = Hash.new { |h, k| h[k] = Host.new(k) }
    end
    include Singleton
    # clear the hosts
    def clear
      @hash.clear
    end
    # clear the hosts
    def self.clear
      instance.clear
    end
    def size
      @hash.size
    end
    # clear the hosts
    def self.size
      instance.size
    end
    # get the source for a given host, path, source
    def get(host)
      @hash[host]
    end
    # get the source for a given host, path, source
    def self.get(host)
      instance.get(host)
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
    # clear the roots
    def clear
      @hash.clear
    end
    # clear the roots
    def self.clear
      instance.clear
    end
    # how many roots are there
    def size
      @hash.size
    end
    # how many roots are there
    def self.size
      instance.size
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
          b.yield @hash[key]
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
  # This singleton contains all of the Excluded paths
  class Excludes
    # Initialize
    def initialize
      @hash = Hash.new { |h, k| h[k] = Hash.new { |he, ke| he[ke] = Exclude.new(k, ke) } }
      @evals = []
    end
    include Singleton
    # clear the hosts
    def self.clear
      @hash.clear
    end
    # get the source for a given host, path, source
    def get(host, path)
      @hash[host][path]
    end
    # get the source for a given host, path, source
    def self.get(host, path)
      instance.get(host, path)
    end
    # find excludes for a host, path pair
    # @return [Array] a list of paths to exclude
    def find(host, path)
      ret = Array.new
      regex = File.expand_path(path) + '/'
      @hash[host].each_key do |key|
        if key.match regex
          ret.push key.sub(path, '')
        end
      end
      ret
    end
    def self.find(host, path)
      instance.find(host, path)
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
      if path.match(/^[a-z]*:/)
puts "swap path and source"
        x = path
        path = source
        source = x
      end
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
  # Information about a network
  class Network
  end
  # The Host class holds information for a given device
  class Host
    # the name of the host
    attr_reader :name
    # Initialize
    def initialize(host)
      @name = host
    end
    def networks()
      [ Network.new ]
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
    # the copy_factor is the number of copies to make per hour
    def copy_factor
      1
    end
  end
  class Exclude
    # initialize
    def initialize(host, path)
      @host = host
      @path = path
    end
  end
end
