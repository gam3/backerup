
module BackerUp
  class Backups
    def initialize(config)
      ret = []
      root = config.root
      active_path = File.join(root, config.active_name)
      static_path = File.join(root, config.static_name)
      partial_path = File.join(root, config.partial_name)
      paths = []
      @host = Hash.new {|h,k| h[k] = Array.new }
      config.hosts.each do |host, data|
        data.backups.each do |backup_data|
          paths.push backup_data.path
        end
        data.excludes.each do |backup_data|
          paths.push  backup_data
        end
        data.backups.each do |backup_data|
          next unless backup_data.type?
          backup = Backup.new(
            :root => root,
            :active_path => File.join(active_path, host, backup_data.path, ''),
            :static_path => File.join(static_path, host, backup_data.path, ''),
            :partial_path => File.join(partial_path, host, backup_data.path, ''),
            :host => host,
            :path => backup_data.path,
            :bwlimit => 1000,
            :data => backup_data,
            :all_paths => paths.select { |x| x != backup_data.path },
          )
          ret.push backup
          @host[host].push backup
        end
      end
      @ret = ret
    end
    def sources
      '99'
    end
    def each
      @ret.each do |entry|
        yield entry
      end
    end
    class Backup
      attr_reader :active_path
      attr_reader :static_path
      attr_reader :partial_path
      attr_reader :path
      def initialize(args)
        @root = args[:root]
        @host = args[:host]
#          @config = args[:config] or raise 'no config'
        @active_path = args[:active_path]
        @static_path = args[:static_path]
        raise "no static_path" unless @static_path
        raise "no active_path" unless @active_path
        @path = args[:path] or raise('no path')
        @partial_path = args[:partial_path]
        @data = args[:data]
        @bwlimit = args[:bwlimit] || nil
        @all_paths = args[:all_paths]
        @running = true;
      end
      def logfile
        BackerUp.logger
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
      def name
        'back name'
      end
      def command
        ret = []
        ret.push 'rsync'
        ret.push '-a'
        ret.push '--out-format=%i|%n'
        ret.push '--delete'
        if @partial_path
          ret.push '--partial'
          ret.push "--partial-dir=#{@partial_path}"
        end
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
