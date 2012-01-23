module EventMachine
  module RTMP
    class Logger

      def self.log(level, message)
        @@file ||= File.open('/Users/jcoene/Desktop/em-rtmp.log', 'a')
        @@file.write("[#{Time.now.strftime('%T')}] [#{level}] #{message}\n")
        @@file.flush
      end

      def self.debug(message)
        log 'DEBUG', message
      end

      def self.info(message)
        log 'INFO', message
      end

      def self.error(message)
        log 'ERROR', message
      end

      def self.print(message)
        log message
        puts message
      end

    end
  end
end
