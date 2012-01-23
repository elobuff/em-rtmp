require "stringio"
require "em-rtmp/io_helpers"

module EventMachine
  module RTMP
    class Buffer < StringIO
      include EventMachine::RTMP::IOHelpers

      # Gets the number of remaining bytes in the buffer
      #
      # Returns an Integer representing the number of bytes left
      def remaining
        size - pos
      end

      # Truncate the buffer to nothing and set the position to zero
      #
      # Returns the new position (zero)
      def reset
        truncate 0
        seek 0
      end

  end
end
