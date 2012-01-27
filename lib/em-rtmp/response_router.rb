module EventMachine
  module RTMP
    class ResponseRouter < ConnectionDelegate

      attr_accessor :active_response

      # Create a new response router object to delegate to. Start with a state
      # of looking for a fresh header.
      #
      # Returns nothing
      def initialize(connection)
        super connection
        @state = :wait_header
      end

      # Called by the connection when the buffer changes and it's appropriate to
      # delegate to the response router. Take action depending on our state.
      #
      # Returns nothing
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

      # Receive a fresh header, add it to the appropriate response and receive
      # a chunk of data for that response.
      #
      # header - Header to receive and act on
      #
      # Returns nothing
      def receive_header(header)
        response = Response.find_or_create(header.channel_id, @connection)
        response.add_header header
        receive_chunk response
      end

      # Receive a chunk of data for a given response. Change our state depending
      # on the result of the chunk read. If it was read in full, we'll look for
      # a header next time around. Otherwise, we will continue to read into that
      # chunk until it is satisfied.
      #
      # If the response is completely received, we'll clone it and route that to
      # the appropriate action, then reset that response so that it can receive something
      # else in the future.
      #
      # response - the Response object to act on
      #
      # Returns nothing
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

      # Route any response to its proper destination. AMF responses are routed to their
      # pending request. Chunk size updates the connection, others are ignored for now.
      #
      # response - Response object to route or act on.
      #
      # Returns nothing.
      def route_response(response)
        case response.header.message_type
        when :amf0
          response.message = Message.new version: 0
          response.message.decode response.body
          Logger.info "head: #{response.header.inspect}"
          Logger.info "amf0: #{response.message.inspect}"
          route_amf :amf0, response
        when :amf3
          response.message = Message.new version: 3
          response.message.decode response.body
          Logger.info "head: #{response.header.inspect}"
          Logger.info "amf3: #{response.message.inspect}"
          route_amf :amf3, response
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

      # Route an AMF response to it's pending request
      #
      # version - AMF version (:amf0 or :amf3)
      # response - Response object
      #
      # Returns nothing
      def route_amf(version, response)
        Logger.debug "routing #{version} response for tid #{response.message.transaction_id}"
        if pending_request = PendingRequest.find(version, response.message.transaction_id, @connection)
          if response.message.success?
            pending_request.request.succeed(response)
          else
            pending_request.request.fail(response)
          end
          pending_request.delete
        else
          Logger.error "unable to find a matching transaction"
        end
      end

    end
  end
end
