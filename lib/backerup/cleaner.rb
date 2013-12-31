require 'date'
require 'time'
require 'fileutils'
require 'set'

require 'backerup/backups'

module BackerUp
  # This class contains the collector application of backerup system
  class AppCleaner
    def initialize(roots)
      @roots = roots
    end
    def self.dry_run
      self.run(true)
    end
    def self.run(dry_run = false)
      @roots = Array.new
      Backups.roots.each do |root|
        @roots.push root
      end
      threads = Array.new
      @roots.each do |root|
        threads.push Thread.new { Cleaner.clean(root) }
      end
      while threads.size > 0
	threads = threads.find_all { |thread| !thread.join(1) }
      end
    end
  end
  # Clean up the backup by sieving the directories
  class Cleaner
    @@types = [ :hourly, :daily, :weekly, :monthly, :yearly ]
    @@config = Hash[
      :hourly  => Hash[ span:  32, age: [[0, 2], [12, 1]] ],
      :daily   => Hash[ span:   9, age: [[0, 4], [3, 2], [7, 1]] ],
      :weekly  => Hash[ span:  20, age: [[0, 5], [3, 3], [4, 1]] ],
      :monthly => Hash[ span:  12, age: [[0, 4], [6, 2]] ],
      :yearly  => Hash[ span: 100, age: [[0, 12], [2, 6], [3, 1]] ],
    ]
    def self.clean(root)
      we = self.new(root)
      we.clean
    end

    def initialize(root)
      @root = root;
      @now = Time.now()
      @config = @@config
    end
    def seive(type, time)
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
    def next_type(type)
      case type
      when :hourly
	:daily
      when :daily
	:weekly
      when :weekly
	:monthly
      when :monthly
	:yearly
      else
	raise type
      end
    end


    def clean
      root = @root
      now = Time.now()
      parts = @@types.join(',')
      match = "{#{parts}}-#{"[0-9]" * 14 }"
      regexp = /(#{@@types.join('|')})-([0-9]+$)/
puts "Cleaning #{root}"
      Dir.glob(File.join(root, "." + match)) do |name|
puts "rm -rf #{name}"
      end
      seive_hash = Hash[
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
	seive_key = seive(type, time)
	seive_hash[type][seive_key].push name
      end
pp seive_hash
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
          puts "rename #{name} #{next_type(type)}-#{rawtime}"
#          File.rename(name, "#{next_type(type)}-#{rawtime}") unless @dry_run
          rename_count += 1
	end
      end
    end
  end # class Cleaner
end # module
__END__
#!/usr/bin/env ruby
require 'pp'
require 'date'
require 'time'
require 'fileutils'
require 'set'

Dir.chdir('/opt/backerup') or exit(4)

@touch = false
@now = Time.now()
@verbose = true

def mult(type)
  case type
  when :hourly
    mult = 60 * 60
  when :daily
    mult = 24 * 60 * 60
  when :weekly, :monthly
    mult = 7 * 24 * 60 * 60
  when :monthly
    mult = 7 * 24 * 60 * 60  # weeks
  else
    raise "unknown type #{type}" unless @config[type]
  end
  mult
end

def seive(type, time)
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

def span(type)
  @config[type][:span]
end

def max_files(type)
  case type
  when :hourly
    60
  when :daily
    24
  when :weekly
    7
  when :monthly
    30
  when :yearly
    52 # FIXME
  else
    raise type
  end
end

def next_type(type)
  case type
  when :hourly
    :daily
  when :daily
    :weekly
  when :weekly
    :monthly
  when :monthly
    :yearly
  else
    raise type
  end
end

parts = types.join(',')

match = "{#{parts}}-#{"[0-9]" * 14 }"
regexp = /(#{types.join('|')})-([0-9]+$)/
daily = Hash.new

def get_count(type, units, time = Time.now, size)
  raise "unknown type #{type}" unless @config[type]
  case type
  when :hourly
    min = 60    # minutes
  when :daily
    min = 24    # hours
  when :weekly 
    min = 7     # days
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

seive_hash = Hash[
  hourly: Hash.new { |h,k| h[k] = Array.new },
  daily: Hash.new { |h,k| h[k] = Array.new },
  weekly: Hash.new { |h,k| h[k] = Array.new },
  monthly: Hash.new { |h,k| h[k] = Array.new },
  yearly: Hash.new { |h,k| h[k] = Array.new },
]

Dir.glob("." + match) do |name|
  # remove partial directories
#  FileUtils.rm_rf(name)
end

Dir.glob(match) do |name|
  time = nil
  if m = name.match(regexp)
    type = m[1].to_sym
    rawtime = m[2]
    time = Time.parse(m[2])
  else
    raise "bad name #{$name}"
  end
  FileUtils.touch(name, {:mtime => time}) if @touch
  seive_key = seive(type, time)
  seive_hash[type][seive_key].push name
end

[:hourly, :daily, :weekly, :monthly, :yearly].each do |type|
  seive_hash[type].each do |key, data|
    if m = data[0].match(regexp)
      time = Time.parse(m[2])
    else
      raise 'file lost'
    end

    if time_offset(type, time) > @config[type][:span]
      puts "skip #{data[0]}" if @verbose
      next  # don't deletr files that will be renamed
    end
    (max, keep_count) = get_count(type, time_offset(type, time), time, data.size)
    folder_size = max / keep_count
    if type == :weekly
      puts time.to_date.wday
    end

    mark = Set.new
    if data.size > keep_count
      count = 0
      last = nil
      data.sort.each do |name|
        if m = name.match(regexp)
          time = Time.parse(m[2])
          case type
          when :hourly
            modulo_time = time.min
            sec = (modulo_time.to_i / folder_size).round
          when :daily
            modulo_time = time.hour
            sec = (modulo_time.to_i / folder_size).round
          when :weekly,
            modulo_time = time.to_date.wday
            sec = (modulo_time.to_i / folder_size).round
          when :monthly
            modulo_time = time.to_date.day
            sec = (modulo_time.to_i / folder_size).round
          when :yearly
            modulo_time = time.to_date.cweek
            sec = (modulo_time.to_i / folder_size).round
          end
          if last == sec
            puts "unlink #{name}" if @verbose
            File.rename(name, "."+name) unless @dry_run
            FileUtils.rm_rf("."+name)
          end
          last = sec
        else
          raise 'file lost'
        end
      end
    end
  end
end

@dry_run = false

@verbose = true

count = 0
Dir.glob(match) do |name|
  time = nil
  if m = name.match(regexp)
    type = m[1].to_sym
    rawtime = m[2]
    time = Time.parse(m[2])
  else
    raise "bad name #{$name}"
  end
  next if type == :yearly

  if time_offset(type, time) > @config[type][:span]
    puts "rename #{name} #{next_type(type)}-#{rawtime}" if @verbose
    File.rename(name, "#{next_type(type)}-#{rawtime}") unless @dry_run
    count += 1
  end
end

