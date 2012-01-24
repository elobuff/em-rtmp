module EventMachine
  module RTMP
    class Response < ConnectionDelegate
      @@channels = []

      attr_accessor :channel_id, :header, :body, :waiting_on_bytes

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

      # Read the next data chunk from the stream
      #
      # Returns the instance body
      def read_next_chunk
        raise "No more data to read from stream" if header.body_length < body.length
        raise "Negative read should not happen" if (header.body_length - body.length) < 0

        if waiting_on_bytes > 0
          read_size = waiting_on_bytes
        else
          chunk_size = @connection.chunk_size
          read_size = [header.body_length - body.length, chunk_size].min
        end

        Logger.print "want #{read_size} (#{body.length}/#{header.body_length})"

        data = read(read_size)
        self.body << data

        if data.length != read_size
          self.waiting_on_bytes = read_size - data.length
          Logger.print "read_next_chunk got insufficient data (#{data.length}/#{read_size}), waiting"
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
        Logger.print "response complete? #{complete} (#{body.length}/#{header.body_length})"
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
