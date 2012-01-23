require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

desc 'Run all specs in the spec directory'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
