require "em-rtmp/connection_delegate"

module EventMachine
  module RTMP
    class Request < ConnectionDelegate

      include EventMachine::Deferrable

      # An RTMP packet includes a header and a body. Each packet is typically no
      # longer than 128 bytes, including the header. Multiple streams can be
      # ongoing (and interweaving) at the same time, so we track them via their
      # stream id.

      # The request implementation here references a Header object and a message body.
      # The body can be any object that responds to to_s.

      attr_accessor :header, :body, :message

      # Initialize, setting attributes
      #
      # attrs - Hash of attributes to write
      #
      # Returns nothing
      def initialize(connection)
        super connection
        self.header = Header.new
        self.body = ""
      end

      # Send the request
      #
      # Returns the bytes written
      def send
        bytes_sent = 0

        # Set the header length to that of our body
        header.body_length = body.length

        # We get our maximum chunk size from the connection
        chunk_size = @connection.chunk_size

        # The chunk count is the minimum number of packets required
        chunk_count = (body.length / chunk_size.to_f).ceil

        for chunk in 1..chunk_count
          header.header_length = chunk==1 ? 12 : 1
          chunk_begin = (chunk-1) * (chunk_size)
          chunk_end = [chunk_begin + (chunk_size-1), (body.length-1)].min
          chunk_body = body[chunk_begin..chunk_end]
          bytes_sent += send_chunk chunk_body
        end

        bytes_sent
      end

      # Send a chunk to the stream
      #
      # body - Body string to write
      #
      # Returns the number of bytes written
      def send_chunk(body)
        Logger.print "sending chunk #{body.length}", indent: 1
        write header.encode
        write body.to_s
      end

    end
  end
end
