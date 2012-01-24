module EventMachine
  module RTMP
    class Request < ConnectionDelegate

      # An RTMP packet includes a header and a body. Each packet is typically no
      # longer than 128 bytes, including the header. Multiple streams can be
      # ongoing (and interweaving) at the same time, so we track them via their
      # stream id.

      # The request implementation here references a Header object and a body.
      # The body can be any object that responds to to_s.

      attr_accessor :connection, :body, :header

      # Initialize, setting attributes
      #
      # attrs - Hash of attributes to write
      #
      # Returns nothing
      def initialize(attrs={})
        attrs.each {|k,v| send "#{k}=", v }
        self.header ||= Header.new
        self.body ||= ""
      end

      # Write a request to the IO stream
      #
      # io - IO stream to write to
      #
      # Returns the bytes written
      def write(io)
        # Set the header length to that of our body
        bytes_sent = 0
        header.body_length = body.length
        chunk_count = (body.length / chunk_size.to_f).ceil

        for chunk in 1..chunk_count
          header.header_length = chunk==1 ? 12 : 1
          chunk_begin = (chunk-1) * (chunk_size)
          chunk_end = [chunk_begin + (chunk_size-1), (body.length-1)].min
          chunk_body = body[chunk_begin..chunk_end]
          bytes_sent += write_chunk chunk_body
        end

        bytes_sent
      end

      # Write a chunk to the stream
      #
      # body - Body object to write
      #
      # Returns the number of bytes written
      def write_chunk(body)
        write header.encode
        write body.to_s
      end

    end
  end
end
