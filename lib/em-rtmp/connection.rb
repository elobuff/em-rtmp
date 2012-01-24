require "em-rtmp/io_helpers"

module EventMachine
  module RTMP
    class Connection < EventMachine::Connection
      include IOHelpers

      attr_accessor :state, :chunk_size

      # Initialize the connection and setup our handshake
      #
      # Returns nothing
      def initialize
        super
        @buffer = Buffer.new
        @chunk_size = 128
        @response_router = ResponseRouter.new(self)
        @handshake = Handshake.new(self)

        change_state :connecting
      end

      # Reads from the buffer, to facilitate IO operations
      #
      # Returns the result of the read
      def read(length)
        Logger.print "reading #{length} bytes from buffer"
        @buffer.read length
      end

      # Writes data to the EventMachine connection
      #
      # Returns nothing
      def write(data)
        Logger.print "sending #{data.length} bytes"
        send_data data
      end

      def bytes_waiting
        @buffer.remaining
      end

      # Used to track changes in state
      #
      # Returns nothing
      def change_state(state)
        Logger.print "state changed from #{@state} to #{state}", caller: caller, indent: 1
        @state = state
      end

      # Start the handshake process when our connection is completed.
      def connection_completed
        Logger.print "connection completed, issuing rtmp handshake"
        change_state :handshake
        @handshake.issue_challenge
      end

      # called when the connection is terminated
      def unbind
        Logger.print "disconnected"
        change_state :disconnected
      end

      # Receives data and offers it to the appropriate delegate object.
      # Fires a method call to buffer_changed to take action.
      #
      # Returns nothing
      def receive_data(data)
        Logger.print "received #{data.length} bytes"
        @buffer.append data
        buffer_changed
      end

      # Called when the buffer is changed, indicating that we may want
      # to change state or delegate to another object
      #
      # Returns nothing
      def buffer_changed

        until bytes_waiting < 1 do
          case state
          when :connecting
            raise RTMPError, "Should not receive data while connecting"
            break

          when :handshake
            if @handshake.buffer_changed == :handshake_complete
              Logger.print "handshake complete"
              @handshake = nil
              change_state :ready
            end
            break

          when :ready
            if header = Header.new(connection: self).populate_from_stream
              Logger.print "routing new header for channel #{header.channel_id}, type: #{header.message_type}, length: #{header.body_length}"
              @response_router.receive_header header
            end
            break

          end
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
        change_state :handshake
        @handshake.issue_challenge
      end
    end

  end
end
