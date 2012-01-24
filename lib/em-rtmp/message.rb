module EventMachine
  module RTMP
    class Message

      class << self
        attr_accessor :transaction_id
      end

      attr_accessor :_amf_data, :_amf_error, :_amf_unparsed
      attr_accessor :version, :command, :transaction_id, :values

      # Initialize, setting attributes as given
      #
      # attrs - Hash of attributes
      #
      # Returns nothing
      def initialize(attrs={})
        attrs.each {|k,v| send("#{k}=", v)}
        self.command ||= nil
        self.transaction_id ||= self.class.next_transaction_id
        self.values ||= []
        self.version ||= 0x00
      end

      def amf3?
        version == 0x03
      end

      # Encode this message with the chosen serializer
      #
      # Returns a string containing an encoded message
      def encode
        Logger.print "encoding #{self.inspect}"
        class_mapper = RocketAMF::ClassMapper.new
        ser = RocketAMF::Serializer.new class_mapper

        if amf3?
          ser.stream << "\x00"
        end

        ser.serialize 0, command
        ser.serialize 0, transaction_id

        if amf3?
          ser.stream << "\x05"
          ser.stream << "\x11"
          ser.serialize 3, values.first
        else
          values.each do |value|
            ser.serialize 0, value
          end
        end

        ser.stream
      end

      def decode(string)
        class_mapper = RocketAMF::ClassMapper.new
        io = StringIO.new string
        des = RocketAMF::Deserializer.new class_mapper

        begin

          if amf3?
            byte = des.deserialize 3, io
            unless byte == nil
              raise AMFException, "wanted amf3 first byte of 0x00, got #{byte}"
            end
          end

          until io.eof?
            self.values << des.deserialize(0, io)
          end

        rescue => e
          self._amf_data = string
          self._amf_error = e
          self._amf_unparsed = io.read(100_000)
        end

        self.command = values.delete_at(0)
        self.transaction_id = values.delete_at(0)
      end

      def success?
        command != "_error"
      end

      def self.next_transaction_id
        self.transaction_id ||= 0
        self.transaction_id += 1
      end

    end
  end
end
