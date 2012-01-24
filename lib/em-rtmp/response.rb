module EventMachine
  module RTMP
    class Response < ConnectionDelegate
      @@channels = []

      attr_accessor :channel_id, :header, :body

      # Initialize as a logical stream on a given stream ID
      #
      # Returns nothing.
      def initialize(channel_id, connection)
        super connection

        self.channel_id = channel_id
        self.header = Header.new
        self.body = ""
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

        read_size = [header.body_length - body.length, 128].min

        Logger.print "want #{read_size} (#{body.length}/#{header.body_length})"

        self.body << read(read_size)
      end

      # Determine whether or not the stream is complete by checking the length
      # of our body against that we expected from headers
      #
      # Returns true or false
      def complete?
        complete = body.length >= header.body_length
        Logger.print "response complete? #{complete} (#{body.length}/#{header.body_length}"
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
