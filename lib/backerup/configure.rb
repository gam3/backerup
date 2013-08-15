
module BackerUp
  class Configure
    class Host
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
        def initialize
          @rsync = Hash.new
        end
        def rsync(*args, &block)
          rsync = Rsync.new
          rsync.instance_eval &block
          raise "must have a path" unless rsync.path
          @rsync[rsync.path] = rsync
        end
      end
      def initialize(name)
        @name = name
      end
      def backup(*bob, &block)
        backup = Backup.new
        if block
          backup.instance_eval &block
        end
        @backup = backup
      end
    end
    def initialize
      @root = nil
      @hosts = Hash.new
      @static_name = '.static'
      @active_name = '.active'
    end
    def root(*args)
      if args.size == 1
        @root = args[0]
      else
        @root
      end
    end
    def host(name, &block)
      host = @hosts[name] = Host.new(name)
      if block
        host.instance_eval &block
      end
    end
    class Backup
      def initialize
      end
      def root
       '/opt/backerup'
      end
      def host
        'demeter'
      end
      def acitve_path
       '/opt/backerup/.active/burkinaFaso/home/gam3'
      end
      def static_path
       '/opt/backerup/.static/burkinaFaso/home/gam3'
      end
      def command
        [ 'rsync', '-a', '--out-format=%i|%n',
        '--delete',
        '--exclude=movies',
        '--exclude=.VirtualBox',
        '--exclude=src/backfire_10.03.1',
        'burkinaFaso::gam3', acitve_path ]
      end
    end
    def backups
      [ Backup.new ]
    end
  end
end

