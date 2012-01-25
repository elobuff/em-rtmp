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
          Logger.debug "Heartbeat Pulsing"
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
