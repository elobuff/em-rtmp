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

      def self.print(message, options={})
        @@previous_indent ||= 0

        options[:caller] ||= caller
        options[:indent] ||= 0
        caller_splat = options[:caller][0].split(":")
        ruby_file = caller_splat[0].split("/").last
        ruby_line = caller_splat[1]
        ruby_method = caller_splat[2].match(/`(.*)'/)[1]

        puts "" if @@previous_indent != options[:indent]
        indent = ">" * (options[:indent] * 2)
        puts "%s%-#{30-indent.length}s%-30s%s" % [indent, "#{ruby_file}:#{ruby_line}", ruby_method, message.encode('UTF-8')]

        @@previous_indent = options[:indent]
      end

    end
  end
end
