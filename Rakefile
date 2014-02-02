require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

desc 'Run all specs in the spec directory'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Load an interactive console in our environment'
task :console do
  require "eventmachine"
  require "em-rtmp"
  require "irb"
  require "irb/completion"
  module EventMachine
    module RTMP
      ARGV.clear
      IRB.start
    end
  end
end
