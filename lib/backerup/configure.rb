require 'pp'

require 'resolv'

module BackerUp
  class Assertion < Exception; end
  class Skip < Assertion; end
  class Common
    def skip msg = nil, bt = caller
      @skip = [ msg, bt ]
      raise BackerUp::Skip, msg, bt
    end
    def exclude *paths
      @excludes ||= []
      @excludes += paths
    end
  end
  class Configure < Common
    def hostname(name = :default, &block)
    end
    def backerup(name = :default, &block)
      begin
      if block
        self.instance_eval &block
      else
        @backerup
      end
      rescue Skip => x
        puts "This is no Skip for backerup blocks"
      rescue
        raise
      end
    end
    class Host < Common
      attr_accessor :backups
      attr_accessor :excludes
      class Backup < Common
        class Rsync
          def path(*bob)
            if bob.size == 1
              @path = bob[0]
            end
            @path
          end
          def source_path(*bob)
            if bob.size == 1
              @source_path = bob[0]
            end
            @source_path
          end
        end
        attr_reader :path
        def initialize(path)
          @path = path
          @excludes = Array.new
        end
        attr_reader :excludes
        attr_reader :type
        def partial
          @partial = true
        end
        def minsize(limit)
          @minsize = limit
        end
        def maxsize(limit)
          @maxsize = limit
        end
        def bandwidth(limit)
          @bwlimt = limit
        end
        def bwlimit(limit)
          @bwlimt = limit
        end
        def bwlimit(*args)
        end
        def exclude(*args, &block)
          if args.size > 0
            args.each do |path|
              @excludes.push path
            end
          else
            raise 'no path'
          end
        end
        def rsync(*args, &block)
          rsync = Rsync.new
          rsync.instance_eval &block
          raise "duplicate backup method" if @type
          @type = rsync
        end
        def type?
          !@type.nil?
        end
      end
      def initialize(name)
        @name = name
        @backups = Array.new
        @excludes = Array.new
      end
      def backup(path, &block)
        backup = Backup.new(path)
        @backups.push backup
        begin
          if block
            backup.instance_eval &block
          end
        rescue Skip => x
puts "Skip #{x}" 
        end
      end
    end
    def initialize
      @root = nil
      @hosts = Hash.new
      @static_name = '.static'
      @active_name = '.active'
    end
    attr_accessor :active_name
    attr_accessor :static_name
    attr_accessor :hosts
    def root(*args)
      if args.size == 1
        @root = args[0]
      else
        @root || @backerup.root
      end
    end
    def host(name, &block)
      @ips = Resolv.getaddress name
      begin
        host = @hosts[name] = Host.new(name)
        if block
          host.instance_eval &block
        end
      rescue Skip => x
# skip
      rescue => x
        puts "rescue #{x}"
        raise x
      end
    end
    class Backups
      def initialize(config)
        ret = []
        root = config.root
        active_path = File.join(root, config.active_name)
        static_path = File.join(root, config.static_name)
        paths = []
        config.hosts.each do |host, data|
          data.backups.each do |backup_data|
            paths.push  backup_data.path
          end
          data.excludes.each do |backup_data|
            paths.push  backup_data
          end
          data.backups.each do |backup_data|
            next unless backup_data.type?
            ret.push Backup.new(
              :root => root,
              :active_path => File.join(active_path, host, backup_data.path, ''),
              :static_path => File.join(static_path, host, backup_data.path, ''),
              :host => host,
              :path => backup_data.path,
              :bwlimit => 1,
              :data => backup_data,
              :all_paths => paths.select { |x| x != backup_data.path },
            )
          end
        end
        @ret = ret
      end
      def each
        @ret.each do |entry|
          yield entry
        end
      end
      class Backup
        attr_reader :active_path
        attr_reader :static_path
        attr_reader :path
        def logfile
          @log ||= Logger::Logger.new('/tmp/logger')
        end
        def initialize(args)
          @root = args[:root]
          @host = args[:host]
          @active_path = args[:active_path]
          @static_path = args[:static_path]
          raise "no static_path" unless @static_path
          raise "no active_path" unless @active_path
          @path = args[:path] or raise('no path')
          @data = args[:data]
          @bwlimit = args[:bwlimit] || nil
          @all_paths = args[:all_paths]
        end
        def root
         @root
        end
        def host
          @host
        end
        def active_path
         @active_path
        end
        def static_path
         @static_path
        end
        def command
          ret = []
          ret.push 'rsync'
          ret.push '-a'
          ret.push '--out-format=%i|%n'
          ret.push '--delete'
          if @bwlimit
            ret.push "--bwlimit=#{@bwlimit}"
          end
          @all_paths.each do |exclude|
            if exclude.match(/^#{@path}\//)
              t = exclude.sub(/^#{@path}\//, '')
              ret.push "--exclude=#{t}"
            end
          end
          @data.excludes.each do |exclude|
            t = exclude.sub(/^#{@path}\//, '')
            ret.push "--exclude=#{t}"
          end
          ret.push "#{@host}::#{@data.type.source_path}"
          ret.push "#{File.join @active_path, ''}"
          logfile.debug(ret.join(' '))
          ret
        end
      end
    end
  end
end

