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

desc 'Start the test'
task :test do
  require "eventmachine"
  require "em-rtmp"
  EventMachine.run do
    connection = EventMachine::RTMP.ssl_connect '216.133.234.22', 2099

    connection.on_handshake_complete do
      req = EventMachine::RTMP::ConnectRequest.new connection
      req.swfUrl = 'app:/mod_ser.dat'
      req.tcUrl = 'rtmps://prod.na1.lol.riotgames.com:2099'
      req.send
    end

    connection.on_ready do
      obj = RocketAMF::Values::RemotingMessage.new
      obj.destination = "playerStatsService"
      obj.operation = "getRecentGames"
      obj.body = [32310898]

      req = EventMachine::RTMP::Request.new connection
      req.header.channel_id = 3
      req.header.message_stream_id = 0
      req.header.message_type_id = 17

      req.message.version = 3
      req.message.command = nil
      req.message.values = [obj]

      req.body = req.message.encode

      req.callback do |res|
        p "I GOT A MOTHERFUCKING CALLBACK!"
      end

      req.errback do |res|
        p "Couldn't do it..."
      end

      req.send
    end
#
#    connection.on_ready do
#      obj = RocketAMF::Values::RemotingMessage.new
#      obj.destination = "playerStatsService"
#      obj.operation = "getRecentGames"
#      obj.body = [32310898]
#
#      req = EventMachine::RTMP::Request.new connection
#      req.header.channel_id = 3
#      req.header.message_stream_id = 0
#      req.header.message_type_id = 17
#
#      req.message.version = 3
#      req.message.command = nil
#      req.message.values = [obj]
#
#      req.body = req.message.encode
#
#      req.callback do |res|
#        p "I GOT A MOTHERFUCKING CALLBACK!"
#      end
#
#      req.errback do |res|
#        p "Couldn't do it..."
#      end
#
#      req.send
#    end

  end
end
