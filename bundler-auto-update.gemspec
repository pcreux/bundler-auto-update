# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bundler_auto_update/version"

Gem::Specification.new do |s|
  s.name        = "bundler-auto-update"
  s.version     = Bundler::AutoUpdate::VERSION
  s.authors     = ["Philippe Creux"]
  s.email       = ["pcreux@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Auto update your Gemfile}
  s.description = %q{Attempt to update every single gem of your Gemfile to its latest patch, minor then major release. Runs a test command to ensure the update succeeded}

  s.default_executable = %q{bundle-auto-update}

  s.add_development_dependency "rspec", '~> 3.5'
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba", "~> 0.14.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
