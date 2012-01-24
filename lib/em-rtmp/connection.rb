require "em-rtmp/io_helpers"

module EventMachine
  module RTMP
    class Connection < EventMachine::Connection
      include IOHelpers

      attr_accessor :state, :buffer

      # Initialize the connection and setup our handshake
      #
      # Returns nothing
      def initialize
        super
        self.buffer = Buffer.new
        self.state = :handshake
        @handshake = Handshake.new(self)
      end

      # Reads from the buffer, to facilitate IO operations
      #
      # Returns the result of the read
      def read(length)
        Logger.print "reading #{length} bytes from buffer"
        buffer.read length
      end

      # Used to track changes in state
      #
      # Returns nothing
      def state=(state)
        Logger.print "state changed to #{state}", caller: caller
        @state = state
      end

      # Writes data to the EventMachine connection
      #
      # Returns nothing
      def write(data)
        Logger.print "sending #{data.length} bytes"
        send_data data
      end

      # Start the handshake process when our connection is completed.
      def connection_completed
        Logger.print "connection completed, issuing rtmp handshake"
        @handshake.issue_challenge
      end

      # Receives data and offers it to the appropriate delegate object.
      # Fires a method call to buffer_changed to take action.
      #
      # Returns nothing
      def receive_data(data)
        Logger.print "received #{data.length} bytes"
        self.buffer.append data
        buffer_changed
      end

      # Called when the buffer is changed, indicating that we may want
      # to change state or delegate to another object
      #
      # Returns nothing
      def buffer_changed
        case state
        when :handshake
          if @handshake.buffer_changed == :handshake_complete
            Logger.print "handshake complete"
            @handshake = nil
            self.state = :connect
          end
        when :connect
          # Handle connect state responses
        else
          # Here we will route to other handlers
        end
      end
    end

    # A secure connection behaves identically except that it delays the
    # RTMP handshake until after the ssl handshake occurs.
    class SecureConnection < Connection

      # When the connection is established, make it secure before
      # starting the RTMP handshake process.
      def connection_completed
        Logger.print "connection completed, starting tls"
        start_tls verify_peer: false
      end

      # Connection is now secure, issue the RTMP handshake challenge
      def ssl_handshake_completed
        Logger.print "ssl handshake completed, issuing rtmp handshake"
        @handshake.issue_challenge
      end
    end

  end
end
