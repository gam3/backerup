require 'pp'

module BackerUp
  class Configure
    def backerup(name = :default, &block)
      if block
        self.instance_eval &block
      else
        @backerup
      end
    end
    class Host
      attr_accessor :backups
      class Backup
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
          @rsync = Hash.new
          @excludes = Array.new
        end
        attr_reader :excludes
        attr_reader :type
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
      end
      def initialize(name)
        @name = name
        @backups = Array.new
      end
      def backup(path, &block)
        backup = Backup.new(path)
        if block
          backup.instance_eval &block
        end
        @backups.push backup
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
      host = @hosts[name] = Host.new(name)
      if block
        host.instance_eval &block
      end
    end
    class Backups
      def initialize(config)
        ret = []
        root = config.root
        active_path = File.join(root, config.active_name)
        static_path = File.join(root, config.static_name)
        config.hosts.each do |host, data|
          data.backups.each do |backup_data|
            ret.push Backup.new(
              :root => root,
              :active_path => File.join(active_path, host, backup_data.path, ''),
              :static_path => File.join(static_path, host, backup_data.path, ''),
              :host => host,
              :path => backup_data.path,
              :data => backup_data,
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
        def initialize(args)
          @root = args[:root]
          @host = args[:host]
          @active_path = args[:active_path]
          @static_path = args[:static_path]
          raise "no static_path" unless @static_path
          raise "no active_path" unless @active_path
          @path = args[:path] or raise('no path')
          @data = args[:data]
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
          ret.push '--bwlimit=500'
          ret.push '--max-size=500M'

          @data.excludes.each do |exclude|
            t = exclude.sub(/^#{@path}\//, '')
puts "exclude #{exclude}, #{t}"
            ret.push "--exclude=#{t}"
          end
          ret.push "#{@host}::#{@data.type.source_path}"
          ret.push "#{File.join @active_path, ''}"
puts ret.inspect
          ret
        end
      end
    end
    def backups
raise "is this used"
      [ Backup.new ]
    end
  end
end

