require "em-rtmp/request"

module EventMachine
  module RTMP
    class ConnectRequest < Request

      DEFAULT_PARAMETERS = {
        app: '',
        flashVer: 'WIN 10,1,85,3',
        swfUrl: '',
        tcUrl: '',
        fpad: false,
        capabilities: 239,
        audioCodecs: 3191,
        videoCodecs: 252,
        videoFunction: 1,
        pageUrl: nil,
        objectEncoding: 3
      }

      attr_accessor :app, :flashVer, :swfUrl, :tcUrl, :fpad, :capabilities,
                    :audioCodecs, :videoCodecs, :videoFunction, :pageUrl, :objectEncoding

      # Initialize the request and set sane defaults for an RTMP connect
      # request (transaction_id, command, header values)
      #
      # Returns nothing
      def initialize(connection)
        super connection

        self.header.channel_id = 3
        self.header.message_type = :amf0
        self.header

        self.message = Message.new version: 0
        self.message.command = "connect"
        self.message.transaction_id = 1

        callback do |res|
          Logger.debug "rtmp connect failed, becoming ready"
          @connection.change_state :ready
        end

        errback do |res|
          Logger.debug "rtmp connect failed, closing connection"
          @connection.close_connection
        end
      end

      # Construct a list of parameters given our class attributes, used
      # to form the connect message object.
      #
      # Returns a Hash of symbols => values
      def parameters
        instance_values = Hash[instance_variables.map {|k| [k.to_s[1..-1].to_sym, instance_variable_get(k)]}]
        DEFAULT_PARAMETERS.merge instance_values.select {|k,v| DEFAULT_PARAMETERS.key? k }
      end

      # Given the specific nature of a connect request, we can just set the message
      # values to our params then encode that as our body before sending.
      #
      # Returns the result of super
      def send
        self.message.values = [parameters]
        self.body = message.encode
        super
      end

    end
  end
end
