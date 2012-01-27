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
        self.message = Message.new
        self.body = ""
      end

      # Updates the header to reflect the actual length of the body
      #
      # Returns nothing
      def update_header
        header.body_length = body.length
      end

      # Determines the proper chunk size for each packet we will send
      #
      # Returns the chunk size as an Integer
      def chunk_size
        @connection.chunk_size
      end

      # Determines the number of chunks we will send
      #
      # Returns the chunk count as an Integer
      def chunk_count
        (body.length / chunk_size.to_f).ceil
      end

      # Splits the body into chunks for sending
      #
      # Returns an Array of Strings, each a chunk to send
      def chunks
        (0...chunk_count).map do |chunk|
          offset_start = chunk_size * chunk
          offset_end = [offset_start + chunk_size, body.length].min - 1
          body[offset_start..offset_end]
        end
      end

      # Determine the proper header length for a given chunk
      #
      # Returns an Integer
      def header_length_for_chunk(offset)
        offset == 0 ? 12 : 1
      end

      # Update the header and send each chunk with an appropriate header.
      #
      # Returns the number of bytes written
      def send
        bytes_sent = 0
        update_header

        Logger.info "sending request channel=#{header.channel_id} type=#{header.message_type_id} length=#{header.body_length}"

        for i in 0..(chunk_count-1)
          self.header.header_length = header_length_for_chunk(i)
          bytes_sent += send_chunk chunks[i]
        end

        PendingRequest.create self, @connection

        bytes_sent
      end

      # Send a chunk to the stream
      #
      # body - Body string to write
      #
      # Returns the number of bytes written
      def send_chunk(chunk)
        Logger.debug "sending chunk (#{chunk.length})", indent: 1
        write(header.encode) + write(chunk)
      end

    end
  end
end
