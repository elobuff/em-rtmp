module EventMachine
  module RTMP
    class ResponseRouter

      def initialize(connection)
        @connection = connection
      end

      # Route a new header to a stream
      def receive_header(header)
        response = Response.find_or_create(header.channel_id, @connection)
        response.add_header header
        response.read_next_chunk

        if response.complete?
          Logger.print "response is complete, routing it!"
          route_response response.dup
          response.reset
        end
      end

      def route_response(response)
        case response.header.message_type
        when :amf0
          message = Message.new version: 0
          message.decode response.body
          Logger.print "head: #{response.header.inspect}"
          Logger.print "amf0: #{message.inspect}"
        when :amf3
          message = Message.new version: 3
          message.decode response.body
          Logger.print "head: #{response.header.inspect}"
          Logger.print "amf3: #{message.inspect}"
        when :chunk_size
          connection.chunk_size = response.body.unpack('N')[0]
          Logger.print "setting chunk_size to #{chunk_size}"
        when :ack_size
          ack_size = response.body.unpack('N')[0]
          Logger.print "setting ack_size to #{ack_size}"
        when :bandwidth
          bandwidth = response.body[0..3].unpack('N')[0]
          bandwidth_type = response.body[4].unpack('c')[0]
          Logger.print "setting bandwidth to #{bandwidth} (#{bandwidth_type})"
        else
          Logger.print "cannot route unknown response: #{response}"
        end
      end

    end
  end
end
