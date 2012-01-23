$:.push File.expand_path("../lib", __FILE__)
require "em-rtmp/version"

Gem::Specification.new do |s|
  s.name          = "em-rtmp"
  s.version       = EventMachine::RTMP::VERSION
  s.authors       = ["Jason Coene"]
  s.email         = ["jcoene@gmail.com"]
  s.homepage      = "http://github.com/jcoene/em-rtmp"
  s.summary       = "RTMP support for EventMachine"
  s.description   = s.summary

  s.files         = Dir["lib/**/*"] + ["Rakefile", "Gemfile", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "eventmachine"
  s.add_dependency "RocketAMF", "~> 1.0.0"

  s.add_development_dependency "rspec", "~> 2.8.0"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "growl"
end
