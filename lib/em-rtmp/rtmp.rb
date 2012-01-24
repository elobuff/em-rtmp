module EventMachine
  module RTMP

    class RTMPError < RuntimeError; end
    class HandshakeError < RTMPError; end
    class HeaderError < RTMPError; end
    class MessageError < RTMPError; end

    # Create and establish a connection
    def self.connect(server, port=nil)
      EventMachine.connect server, port, EventMachine::RTMP::Connection
    end

    # Create and establish a secure connection
    def self.ssl_connect(server, port=nil)
      EventMachine.connect server, port, EventMachine::RTMP::SecureConnection
    end

  end
end
