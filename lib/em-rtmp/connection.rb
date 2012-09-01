require "em-rtmp/io_helpers"

module EventMachine
  module RTMP
    class Connection < EventMachine::Connection
      include IOHelpers

      attr_accessor :state, :chunk_size, :channels, :pending_requests

      # Initialize the connection and setup our handshake
      #
      # Returns nothing
      def initialize
        super
        @buffer = Buffer.new
        @chunk_size = 128
        @response_router = ResponseRouter.new(self)
        @handshake = Handshake.new(self)
        @callbacks = { :handshake_complete => [], :ready => [], :disconnected => [] }
        @channels = []
        @pending_requests = {}
        @state = :connecting
      end

      # Used to track changes in state
      #
      # state - Symbol, new state to enter
      #
      # Returns nothing
      def change_state(state)
        return if @state == state
        Logger.info "state changed from #{@state} to #{state}", caller: caller
        @state = state
        run_callbacks state
      end

      # Start the RTMP handshake process
      #
      # Returns nothing
      def begin_rtmp_handshake
        change_state :handshake
        @handshake.issue_challenge
      end

      # Called to add a callback for when the RTMP handshake is
      # completed. Most useful for issuing an RTMP connect request.
      #
      # blk - block to execute
      #
      # Returns nothing
      def on_handshake_complete(&blk)
        @callbacks[:handshake_complete] << blk
      end

      # Called to add a callback for when the RTMP connection has
      # been established and is ready for work.
      #
      # blk - block to execute
      #
      # Returns nothing
      def on_ready(&blk)
        @callbacks[:ready] << blk
      end

      # Called to add a callback for when the TCP connection has
      # been disconnected.
      #
      # blk - block to execute
      #
      # Returns nothing
      def on_disconnected(&blk)
        @callbacks[:disconnected] << blk
      end

      # Called to run the callbacks for a specific event
      #
      # event - symbol representing the event to run callbacks for
      #
      # Returns nothing
      def run_callbacks(event)
        if @callbacks.keys.include? event
          @callbacks[event].each do |blk|
            blk.call
          end
        end
      end

      # Reads from the buffer, to facilitate IO operations
      #
      # Returns the result of the read
      def read(length)
        Logger.debug "reading #{length} bytes from buffer"
        @buffer.read length
      end

      # Writes data to the EventMachine connection
      #
      # Returns nothing
      def write(data)
        Logger.debug "sending #{data.length} bytes to stream"
        send_data data
      end

      # Obtain the number of bytes waiting to be read in the buffer
      #
      # Returns an Integer
      def bytes_waiting
        @buffer.remaining
      end

      # Perform the next step after the connection has been established
      # Called by the Event Machine
      #
      # Returns nothing
      def connection_completed
        Logger.info "connection completed, issuing rtmp handshake"
        begin_rtmp_handshake
      end

      # Change our state to disconnected if we lose the connection.
      # Called by the Event Machine
      #
      # Returns nothing
      def unbind
        Logger.info "disconnected from peer"
        change_state :disconnected
      end

      # Receives data and offers it to the appropriate delegate object.
      # Fires a method call to buffer_changed to take action.
      # Called by the Event machine
      #
      # data - data received
      #
      # Returns nothing
      def receive_data(data)
        Logger.debug "received #{data.length} bytes"
        @buffer.append data
        buffer_changed
      end

      # Called when the buffer is changed, indicating that we may want
      # to change state or delegate to another object
      #
      # Returns nothing
      def buffer_changed

        loop do
          break if bytes_waiting < 1

          begin
            case state
            when :handshake
              if @handshake.buffer_changed == :handshake_complete
                @handshake = nil
                change_state :handshake_complete
              end
              break
            when :handshake_complete, :ready
              @response_router.buffer_changed
              next
            end
          rescue NoMethodError, TypeError, RuntimeError => e
            Logger.error "failure: #{e}"
            retry
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
        Logger.info "connection completed, starting tls"
        start_tls verify_peer: false
      end

      # Connection is now secure, issue the RTMP handshake challenge
      def ssl_handshake_completed
        Logger.info "ssl handshake completed, issuing rtmp handshake"
        begin_rtmp_handshake
      end
    end

  end
end
