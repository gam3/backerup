# Author::    "G. Allen Morris III" (mailto:gam3@gam3.net)
# Copyright:: Copyright (c) 2013-2014 G. Allen Morris III
# License::   GPL 2.0
require 'date'
require 'time'
require 'fileutils'
require 'set'

require 'backerup/backups'

module BackerUp
  # This class contains the collector application of backerup system
  class AppCleaner
    # do a dry run of the cleaner app
    def self.dry_run(root)
      self.run(root, :dryrun => true)
    end
    # run of the cleaner app
    def self.run(root, extra = {})
      cleaner = Cleaner.new(root, extra)
      cleaner.run
    end
    def self.trun(root, extra = {})
      Cleaner.new(root, extra).trun
    end
  end
  # Clean up the backup by sieving the directories
  class Cleaner
    @@types = [ :hourly, :daily, :weekly, :monthly, :yearly ]
    @@config = Hash[
      :hourly   => Hash[ span:  32, age: [[0, 4], [12, 1]] ],
      :daily    => Hash[ span:   9, age: [[0, 4], [3, 2], [7, 1]] ],
      :weekly   => Hash[ span:  52, age: [[0, 5], [3, 3], [4, 1]] ],
      :monthly  => Hash[ span:   0, age: [[0, 4], [6, 2]] ],
      :yearly   => Hash[ span: 100, age: [[0, 26], [2, 6], [3, 1]] ],
    ]
    # run of the cleaner
    def self.clean(root)
      we = self.new(root, true)
      we.clean
    end
    # initialize
    def initialize(root, extra = {})
      @root = root;
      @dry_run = extra[:dryrun]
      @config = @@config
      @extra = extra
    end
    def verbose?
      !!@extra['verbose']
    end
    # run as daemaon that cleans the root periodicly
    def stop
      @running = nil
    end
    def trun
      @thread = Thread.new {
	@running = true
        while @running
	  begin
	    x = rand * (30 * 60)
	    BackerUp::logger.info("Will clean in less than #{(x/60).round + 1} minutes")
	    sleep x
	    while @running
	      run
	      x = (20 * 60) + rand * (20 * 60)
	      BackerUp::logger.info("Next clean in less than #{(x/60).round + 1} minutes")
	      sleep x
	    end
	  rescue => x
	    BackerUp::logger.error("Error #{x}")
	  end
	end
      }
      self
    end
    # get the strftime string for the type
    def type_sieve(type, time)
      case type
      when :hourly
	time.strftime('%Y-%j-%H')
      when :daily
	time.strftime('%Y-%j')
      when :weekly
	time.strftime('%Y-%U')
      when :monthly
	time.strftime('%Y-%m')
      when :yearly
	time.strftime('%Y')
      end
    end
    # get the offset time
    def time_offset(type, time)
      case type
      when :hourly
	((@now - time) / 3600).to_i + 1
      when :daily
	(@now.to_date - time.to_date) + 1
      when :weekly
	((@now.to_date - time.to_date)/7).to_i + 1
      when :monthly
	(@now.year * 12 + @now.month) - (time.year * 12 + time.month) + 1
      else
	(@now.year - time.year) + 1
      end
    end

    # Get the next sieve to use
    def next_type(type)
      case type
      when :hourly
	:daily
      when :daily
	:weekly
      when :weekly
	:yearly
      when :monthly
	:yearly
      else
	raise type
      end
    end

    # Get the maximum number of backups for type
    def get_count(type, units, time = Time.now)
      raise "unknown type #{type}" unless @config[type]
      case type
      when :hourly
	min = 60    # minutes
      when :daily
	min = 24    # hours
      when :weekly 
	min = 7     # days
      when :biweekly 
	min = 14     # days
      when :monthly
	min = 28
      when :yearly
	min = 52    # weeks
      else
	raise "unknown type #{type}" unless @config[type]
      end
      max = min
      last = nil
      if units > @config[type][:span]
	units = @config[type][:span]
      end
      @config[type][:age].each do |frame|
	break if frame[0] >= units
	last = frame[0]
	if min > frame[1]
	  min = frame[1]
	else
	  raise "aging must decrease"
	end
      end
      [max, min]
    end

    # seive
    def sieve(type, n, data)
      regexp = /(#{@@types.join('|')})-([0-9]+$)/
      time = nil
      sieve = Hash.new { |h, k| h[k] = Array.new }
      data.each do |item|
	if m = item.match(regexp)
	  time = Time.parse(m[2])
	  dtime = DateTime.parse(m[2])
	else
          raise "Bad file"
	end
	case type
	when :hourly
	  op = time.min
	when :daily
	  op = time.hour
	when :weekly 
	  op = time.to_date.strftime('%w').to_i
	when :biweekly 
	  op = time.day - 1
	when :monthly
	  op = time.day - 1
	when :yearly
	  op = time.yday
	else
	  raise "unknown type #{type}" unless @config[type]
	end
	sieve[op/n] ||= Array.new
	sieve[op/n].push item
      end
      keep = Array.new
      delete = Array.new
      sieve.each do |key, data|
        sort = data.sort
	keep.push sort.shift
	delete += sort
      end
      [ keep, delete ]
    end

    # delete
    def get_delete(sieve_hash)
      regexp = /(#{@@types.join('|')})-([0-9]+$)/
      ret = []

      [:hourly, :daily, :weekly, :monthly, :yearly].each do |type|
	sieve_hash[type].each do |key, data|
	  if m = data[0].match(regexp)
	    dtime = DateTime.parse(m[2])
	    time = Time.parse(m[2])
	  else
	    raise 'file lost'
	  end
	  (max, keep_count) = get_count(type, time_offset(type, time), time)

	  (keep, remove) = sieve(type, (max / keep_count).ceil, data)
	  if remove
	    ret += remove
	  end
	end
      end
      ret
    end

    # clean
    def run
      root = @root.path
      @now = Time.now()
      parts = @@types.join(',')
      match = "{#{parts}}-#{"[0-9]" * 14 }"
      regexp = /(#{@@types.join('|')})-([0-9]+$)/

      Dir.glob(File.join(root, "." + match)) do |name|
        if @dry_run
          puts "rm -rf #{name}"
	else
	  FileUtils.remove_entry_secure(name)
	end
      end
      sieve_hash = Hash[
	hourly: Hash.new { |h,k| h[k] = Array.new },
	daily: Hash.new { |h,k| h[k] = Array.new },
	weekly: Hash.new { |h,k| h[k] = Array.new },
	monthly: Hash.new { |h,k| h[k] = Array.new },
	yearly: Hash.new { |h,k| h[k] = Array.new },
      ]
      Dir.glob(File.join(root, match)) do |name|
	if m = name.match(regexp)
	  type = m[1].to_sym
	  rawtime = m[2]
	  time = Time.parse(m[2])
	else
	  raise "bad name #{$name}"
	end
	FileUtils.touch(name, {:mtime => time}) if @touch
	sieve_key = type_sieve(type, time)
	sieve_hash[type][sieve_key].push name
      end
      rename_count = 0
      get_delete(sieve_hash).each do |file|
	if @dry_run
	  puts "unlink #{file}"
	else
	  File.rename(file, File.join(File.dirname(file), '.' + File.basename(file)))
	end
        rename_count += 1
      end

      Dir.glob(File.join(root, match)) do |name|
	if m = name.match(regexp)
	  type = m[1].to_sym
	  rawtime = m[2]
	  time = Time.parse(m[2])
	else
	  raise "bad name #{$name}"
	end
	next if type == :yearly

	# rename if the backup if out of its  timeslot

	rename_count = 0
        if time_offset(type, time) > @config[type][:span]
	  dest = File.join(File.dirname(name), "#{next_type(type)}-#{rawtime}")
	  if @dry_run
	    puts "rename #{name} #{dest}"
	  else
            File.rename(name, dest)
          end
          rename_count += 1
	end
      end
    end
  end # class Cleaner
end # module
