module EventMachine
  module RTMP
    class PendingRequest
      attr_accessor :request, :connection

      # Create a new pending request from a request
      #
      # Returns nothing
      def initialize(request, connection)
        self.request = request
        self.connection = connection
      end

      # Delete the current request from the list of pending requests
      #
      # Returns nothing
      def delete
        connection.pending_requests[request.header.message_type].delete(request.message.transaction_id.to_i)
      end

      # Find a request by message type and transaction id
      #
      # message_type - Symbol representing the message type (from header)
      # transaction_id - Integer representing the transaction id
      #
      # Returns the request or nothing
      def self.find(message_type, transaction_id, connection)
        if connection.pending_requests[message_type]
          connection.pending_requests[message_type][transaction_id.to_i]
        end
      end

      # Create a request and add it to the pending requests hash
      #
      # request - Request to add
      #
      # Returns the request
      def self.create(request, connection)
        message_type = request.header.message_type
        transaction_id = request.message.transaction_id.to_i
        connection.pending_requests[message_type] ||= {}
        connection.pending_requests[message_type][transaction_id] = new(request, connection)
        connection.pending_requests[message_type][transaction_id]
      end

    end
  end
end
