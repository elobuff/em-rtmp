require "eventmachine"

require "em-rtmp/buffer"
require "em-rtmp/connection"
require "em-rtmp/logger"
require "em-rtmp/version"

module EventMachine
  module RTMP

    class RTMPError < RuntimeError; end
    class HandshakeError < RTMPError; end

  end
end
