# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "breeze"

Gem::Specification.new do |s|
  s.name        = "breeze"
  s.version     = Breeze::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Markus Bengts"]
  s.email       = ["markus.bengts@gmail.com"]
  s.homepage    = "https://github.com/markus/breeze"
  s.summary     = %q{Thor tasks to manage cloud computing resources and deployments}
  s.description = <<-END_DESCRIPTION
Breeze makes it easy to automate server installation and configuration. It provides
example scripts and configuration files that you can modify and keep in your revision
control system. Thor tasks are provided to create server images, launch server instances etc.
END_DESCRIPTION

  s.rubyforge_project = "breeze"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('thor')
  s.add_dependency('fog-aws')
  s.add_development_dependency "rake"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"
end
