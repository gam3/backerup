# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'backerup/backups'
#require 'backerup/sources'
#require 'backerup/excludes'

module BackerUp
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
       src = source
       src ||= "NO SOURCE AVAILABLE"
       "backup: #{host} '#{path}' '#{src}'"
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
      source = Sources.get_source(@host, @path)
      return nil unless source
      path = @path[source.path.size..-1]
      source.source + File.join(path, '.')
    end
    # Exclude all paths on this host that are children of our path 
    def exclude_paths
      our_path = File.expand_path(self.path)

      ret = Excludes.find(host, our_path)

      Backups.instance.each_path(@host) do |exclude_path|
        next if @path == exclude_path
        if exclude_path.match(/^#{our_path}\//)
          ret.push exclude_path.sub(/^#{@path}\//, '')
        end
      end
      return ret
    end

    # select a network and  allocate bandwidth
    def grab_network(rate = nil)
    end

    #  
    def release_network
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
      return [] unless self.source              # FIXME  This should not be here at all
      ret.push self.source
      ret.push self.active_path
#        logfile.debug(ret.join(' '))
      ret
    end
  end
end
