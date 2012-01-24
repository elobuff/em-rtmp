module EventMachine
  module RTMP
    class Heartbeat < ConnectionDelegate

      def initialize(connection)
        super connection
      end

      def buffer_changed

      end

      def start
        @timer ||= EventMachine::PeriodicTimer.new(15) do
          pulse
        end

        @block = Proc.new do
          Logger.print "Heartbeat Pulsing"
          #req = Request.new(@connection)
          #req.header.channel_id = 3
          #req.header.message_type_id = 17
          #req.message.version = 3
          #req.message.values = [{}]
          #req.body = req.message.encode
          #req.send
        end

        @block.call
      end

      def pulse
        @block.call
      end

      def cancel
        @timer.cancel
        @timer = nil
      end

    end
  end
end
