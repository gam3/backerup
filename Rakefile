# Rakefile for rake        -*- ruby -*-

# Copyright (C) 2013 by G. Allen Morris III  (gam3@gam3.net)
# This Rakefile is free software; G. Allen Morris III
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

ENV['YARDOC']=`which yardoc`

require File.dirname(__FILE__) + '/lib/backerup/version.rb'
require 'rbconfig'
require 'rake/testtask'

#YARD::VERSION.replace(ENV['YARD_VERSION']) if ENV['YARD_VERSION']

task :default => :specs

desc "Builds the gem"
task :gem do
  Gem::Builder.new(eval(File.read('backerup.gemspec'))).build
end

task :doc do |t|
    `test -x $YARDOC && $YARDOC --plugin minitest-spec lib/ specs/`
end
task :docs => :doc

desc "Installs the gem"
task :install => :gem do
  sh "gem install backerup-#{BackerUp::VERSION}.gem --no-rdoc --no-ri"
end

desc "Run all tests"
Rake::TestTask.new(:test) do |t|
     t.libs << "test"
     t.test_files = FileList['specs/spec_*.rb', 'test/test*.rb']
#     t.verbose = true
end
task :tests => :test

desc "Run all specs"
Rake::TestTask.new(:specs) do |t|
     t.libs << "specs"
     t.test_files = FileList[ 'specs/spec_*.rb' ]
end
task :spec => :specs

