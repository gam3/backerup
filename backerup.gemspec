# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "backerup/version"

platform = Gem::Platform.new([nil, 'linux', nil])

Gem::Specification.new do |s|
  s.name        = "backerup"
  s.version     = BackerUp::VERSION
  s.platform    = platform
  s.authors     = ["G. Allen Morris III"]
  s.email       = ["gam3@gam3.net"]
  s.homepage    = "http://www.gam3.org/backerup"
  s.summary     = %q{backup remote systems}
  s.description = %q{Make backups of remote sytems}

#  s.add_runtime_dependency "launchy"
  s.add_development_dependency "yard-minitest-spec", "~>0.1.4"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
