module EventMachine
  module RTMP
    class ResponseRouter < ConnectionDelegate

      attr_accessor :active_response

      def initialize(connection)
        super connection
        @state = :wait_header
      end

      def buffer_changed
        case state
        when :wait_header
          header = Header.read_from_connection(@connection)
          Logger.debug "routing new header channel=#{header.channel_id}, type=#{header.message_type_id} length=#{header.body_length}"
          receive_header header
        when :wait_chunk
          receive_chunk active_response
        end
      end

      # Route a new header to a stream
      def receive_header(header)
        response = Response.find_or_create(header.channel_id, @connection)
        response.add_header header
        receive_chunk response
      end

      def receive_chunk(response)
        response.read_next_chunk

        if response.waiting_in_chunk?
          self.active_response = response
          change_state :wait_chunk
        else
          self.active_response = nil
          change_state :wait_header
        end

        if response.complete?
          Logger.debug "response is complete, routing it!"
          route_response response.dup
          response.reset
        end
      end

      def route_response(response)
        case response.header.message_type
        when :amf0
          message = Message.new version: 0
          message.decode response.body
          Logger.info "head: #{response.header.inspect}"
          Logger.info "amf0: #{message.inspect}"

          if message.success? && message.transaction_id == 1.0
            @connection.change_state :ready
          end

        when :amf3
          message = Message.new version: 3
          message.decode response.body
          Logger.info "head: #{response.header.inspect}"
          Logger.info "amf3: #{message.inspect}"
        when :chunk_size
          connection.chunk_size = response.body.unpack('N')[0]
          Logger.info "setting chunk_size to #{chunk_size}"
        when :ack_size
          ack_size = response.body.unpack('N')[0]
          Logger.info "setting ack_size to #{ack_size}"
        when :bandwidth
          bandwidth = response.body[0..3].unpack('N')[0]
          bandwidth_type = response.body[4].unpack('c')[0]
          Logger.info "setting bandwidth to #{bandwidth} (#{bandwidth_type})"
        else
          Logger.info "cannot route unknown response: #{response.inspect}"
        end
      end

    end
  end
end
