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
      def root(new_root)
        @root = new_root
      end
      def root=(new_root)
        @root = new_root
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
#      @ips = Resolv.getaddress name
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
  end
end

