# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "breeze/version"

Gem::Specification.new do |s|
  s.name        = "breeze"
  s.version     = Breeze::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Markus Bengts"]
  s.email       = ["markus.bengts@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "breeze"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('thor')
  s.add_dependency('amazon-ec2')
end
