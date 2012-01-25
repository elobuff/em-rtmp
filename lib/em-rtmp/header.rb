module EventMachine
  module RTMP
    class Header

      # The packet header is read as follows:
      #
      # The first byte (8 bits) is read into two values:
      #    Header type (2 bits)
      #    Stream ID (6 bits)
      #
      # The header type determines a header length, from which the rest of the data may be read:
      #    TYPE    BYTES    DESCRIPTION
      #    0b11    1        Just the header
      #    0b10    4        Above plus timestamp (uint24 big endian)
      #    0b01    8        Above plus body length (uint24 big endian) and message id (uint8 big endian)
      #    0b00    12       Above plus Message stream id (uint32 little endian)

      attr_accessor :header_length, :body_length, :channel_id,
                    :message_type_id, :message_stream_id, :timestamp

      HEADER_DEFAULTS = {
        header_length: 12,
        timestamp: 0,
        channel_id: 3,
        message_type_id: 0,
        message_stream_id: 0
      }

      # RTMP has a variable length header
      # The keys below are binary values which correspond to expected byte lengths
      # (0b00 in header length field would result in an expected 12 byte header)
      HEADER_LENGTHS = {
        0b00 => 12,
        0b01 => 8,
        0b10 => 4,
        0b11 => 1
      }

      # RTMP uses a single byte to represent the message type
      # These are the known values.
      MESSAGE_TYPES = {
        0x00 => :none,
        0x01 => :chunk_size,
        0x02 => :abort,
        0x03 => :ack,
        0x04 => :ping,
        0x05 => :ack_size,
        0x06 => :bandwidth,
        0x08 => :audio,
        0x09 => :video,
        0x0f => :flex, # aka AMF3 data
        0x10 => :amf3_shared_object, # documented as kMsgContainer=16
        0x11 => :amf3,
        0x12 => :invoke, # aka AMF0 data
        0x13 => :amf0_shared_object, # documented as kMsgContainer=19
        0x14 => :amf0,
        0x16 => :flv # documented as aggregate
      }

      # Initialize and set instance variables
      #
      # attrs - Hash of instance variables
      #
      # Returns nothing
      def initialize(attrs={})
        attrs.each {|k,v| send("#{k}=", v)}
      end

      # Inherit values from another header
      #
      # h - other Header object
      #
      # Returns self
      def +(header)
        keys = %w[header_length body_length channel_id message_type_id message_stream_id timestamp]
        other_values = Hash[keys.map {|k| [k, header.instance_variable_get("@#{k}")]}]
        other_values.each do |k, v|
          unless v.nil?
            Logger.print "setting #{k} to #{v}"
            send("#{k}=", v) unless v.nil?
          end
        end
        self
      end

      # Retrieve the message type for our header
      #
      # Returns a symbol or nil
      def message_type
        MESSAGE_TYPES[message_type_id] || "unknown_type_#{message_type_id}".to_sym
      end

      # Set message type as symbol
      #
      # type - message type symbol
      #
      # Returns the id set
      def message_type=(type)
        self.message_type_id = MESSAGE_TYPES.invert[type]
      end

      # Encode the instantiated header to a buffer
      #
      # io - IO destination to write to
      #
      # Returns the buffer
      def encode

        # Set defaults if necessary
        HEADER_DEFAULTS.each do |k, v|
          send("#{k}=", v) if instance_variable_get("@#{k}").nil?
        end

        h_type = HEADER_LENGTHS.invert[header_length]

        buffer = Buffer.new
        buffer.write_bitfield [h_type, 2], [channel_id, 6]

        if header_length >= 4
          buffer.write_uint24_be timestamp
        end

        if header_length >= 8
          buffer.write_uint24_be body_length
          buffer.write_uint8 message_type_id
        end

        if header_length == 12
          buffer.write_uint32_le message_stream_id
        end

        buffer.string
      end

      # Read the header from a connection
      #
      # connection - connection to use
      #
      # Returns a new header instance
      def self.read_from_connection(stream)
        header = new

        begin
          h_type, header.channel_id = stream.read_bitfield(2, 6)
        rescue => e
          raise HeaderError, "Unable to read header type byte from buffer: #{e}"
        end

        unless header.header_length = HEADER_LENGTHS[h_type]
          raise HeaderError, "invalid header type #{h_type}"
        end

        # Stream ID may occupy up to two more bytes depending on the
        # value of the channel_id we have read:
        # 0 - value is second byte + 64
        # 1 - value is third byte * 256 + second byte + 64
        # 2 - low level protocol message (ignore)

        if header.channel_id == 0x00
          header.channel_id = stream.read_uint8 + 64
        elsif header.channel_id == 0x01
          header.channel_id = stream.read_uint8 + 64 + (stream.read_uint8 * 256)
        end

        # The timestamp is a 3-byte uint24. If this matches 0xffffff we will use another 4 bytes
        # after the header as the real timestamp.
        if header.header_length >= 4
          header.timestamp = stream.read_uint24_be
        end

        # The next 3 bytes are the length of the object body, followed by a single byte
        # representing the content type
        if header.header_length >= 8
          header.body_length = stream.read_uint24_be
          header.message_type_id = stream.read_uint8
        end

        # The next 4 bytes are the stream ID
        if header.header_length >= 12
          header.message_stream_id = stream.read_uint32_le
        end

        # If the timestamp was 0xffffff, the next 4 bytes are the real timestamp
        if header.timestamp == 0xffffff
          header.timestamp = stream.read_uint32_be
        end

        header
      end

    end

  end
end
