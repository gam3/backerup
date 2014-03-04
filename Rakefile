# Rakefile for rake        -*- ruby -*-

# Copyright (C) 2013 by G. Allen Morris III  (gam3@gam3.net)
# This Rakefile is free software; G. Allen Morris III
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

require File.dirname(__FILE__) + '/lib/backerup/version.rb'
require 'rbconfig'
require 'rake/testtask'
require 'rdoc/task'

begin
  require 'yard'
rescue LoadError => x
  YARD = nil
end

#YARD::VERSION.replace(ENV['YARD_VERSION']) if ENV['YARD_VERSION']

#task :default => :specs
task :default => [ :check ]

desc "Builds the gem"
task :gem do
  Gem::Builder.new(eval(File.read('backerup.gemspec'))).build
end

#task :doc do |t|
#    `test -x $YARDOC && $YARDOC --plugin minitest-spec lib/ spec/`
#end
#task :docs => :doc

desc "Installs the gem"
task :install => :gem do
  sh "gem install backerup-#{BackerUp::VERSION}.gem --no-rdoc --no-ri"
end

desc "Run all tests and specs"
Rake::TestTask.new(:check) do |t|
    t.libs << "test"
    t.libs << "spec"
    t.test_files = FileList['test/*_test.rb', 'spec/*_spec.rb']
#     t.verbose = true
end

desc "Run all tests"
Rake::TestTask.new(:test) do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']
#     t.verbose = true
end
task :tests => :test

desc "Run all specs"
Rake::TestTask.new(:specs) do |t|
    t.verbose = true
    t.libs << "spec"
    t.test_files = FileList[ 'spec/*_spec.rb' ]
end
task :spec => :specs

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'bin/*', 'spec/*_spec.rb' ]   # optional
  t.options = [ '--plugin', 'minitest-spec' ] # optional
end if YARD

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

