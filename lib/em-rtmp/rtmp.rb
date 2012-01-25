module EventMachine
  module RTMP

    class RTMPError < RuntimeError; end
    class HandshakeError < RTMPError; end
    class HeaderError < RTMPError; end
    class MessageError < RTMPError; end

    # Create and establish a connection
    #
    # server - String, address of server
    # port - Integer, port of server
    #
    # Returns an EventMachine::RTMP::Connection object
    def self.connect(server, port)
      EventMachine.connect server, port, EventMachine::RTMP::Connection
    end

    # Create and establish a secure (SSL) connection
    #
    # server - String, address of server
    # port - Integer, port of server
    #
    # Returns an EventMachine::RTMP::SecureConnection object
    def self.ssl_connect(server, port)
      EventMachine.connect server, port, EventMachine::RTMP::SecureConnection
    end

  end
end
