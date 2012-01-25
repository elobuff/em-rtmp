module EventMachine
  module RTMP
    class Response < ConnectionDelegate
      @@channels = []

      attr_accessor :channel_id, :header, :body, :message, :waiting_on_bytes

      # Initialize as a logical stream on a given stream ID
      #
      # Returns nothing.
      def initialize(channel_id, connection)
        super connection

        self.channel_id = channel_id
        self.header = Header.new
        self.body = ""
        self.waiting_on_bytes = 0
      end

      def reset
        self.body = ""
      end

      # Inherit values from a given header
      #
      # h - Header to add
      #
      # Returns the instance header
      def add_header(header)
        self.header += header
      end

      # Determines the proper chunk size from the connection
      #
      # Returns the chunk size as an Integer
      def chunk_size
        @connection.chunk_size
      end

      # Determines the proper amount of data to read this time around
      #
      # Returns the chunk size as an Integer
      def read_size
        if waiting_on_bytes > 0
          waiting_on_bytes
        else
          [header.body_length - body.length, chunk_size].min
        end
      end

      # Read the next data chunk from the stream
      #
      # Returns the instance body
      def read_next_chunk
        raise "No more data to read from stream" if header.body_length <= body.length

        Logger.debug "want #{read_size} (#{body.length}/#{header.body_length})"

        desired_size = read_size
        data = read(desired_size)
        self.body << data

        if data.length != desired_size
          self.waiting_on_bytes = desired_size - data.length
        else
          self.waiting_on_bytes = 0
        end

        self.body
      end

      def waiting_in_chunk?
        waiting_on_bytes > 0
      end

      # Determine whether or not the stream is complete by checking the length
      # of our body against that we expected from headers
      #
      # Returns true or false
      def complete?
        complete = body.length >= header.body_length
        Logger.debug "response complete? #{complete} (#{body.length}/#{header.body_length})"
        complete
      end

      # Find or create a channel by ID
      #
      # channel_id - ID of channel to find or create
      # connection - Connection to attach
      #
      # Returns a Response instance
      def self.find_or_create(channel_id, connection)
        @@channels[channel_id] ||= Response.new(channel_id, connection)
        @@channels[channel_id]
      end

    end
  end
end
