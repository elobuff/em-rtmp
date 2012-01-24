require "em-rtmp/buffer"
require "em-rtmp/io_helpers"

module EventMachine
  module RTMP
    class ConnectionDelegate
      include IOHelpers

      attr_accessor :state

      # Initialize the connection delegate by storing a reference to
      # the connection
      #
      # Returns nothing.
      def initialize(connection)
        @connection = connection
      end

      # Connection Delegates send read operations directly to the connection

      # Reads from the connection buffer
      #
      # length - Bytes to read
      #
      # Returns the result of the read
      def read(length)
        @connection.read length
      end

      # Connection Delegates send write operations directly to the connection

      # Writes to the connection socket
      #
      # data - Data to write
      #
      # Returns the result of the write
      def write(data)
        @connection.write data
      end

      # Obtain the number of bytes waiting in the buffer
      #
      # Returns an Integer
      def bytes_waiting
        @connection.bytes_waiting
      end

      # Used to track changes in state
      #
      # Returns nothing
      def change_state(state)
        return if @state == state
        Logger.print "state changed from #{@state} to #{state}", caller: caller, indent: 1
        @state = state
      end

    end
  end
end
