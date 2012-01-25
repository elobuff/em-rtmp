module EventMachine
  module RTMP
    class Logger

      LEVEL_DEBUG = 0
      LEVEL_INFO = 1
      LEVEL_ERROR = 2

      @@level = LEVEL_INFO

      class << self
        attr_accessor :level
      end

      def self.level(level)
        @@level = level
      end

      def self.debug(message, options={})
        return unless @@level <= LEVEL_DEBUG
        print message, {level: "DEBUG", caller: caller}.merge(options)
      end

      def self.info(message, options={})
        return unless @@level <= LEVEL_INFO
        print message, {level: "INFO", caller: caller}.merge(options)
      end

      def self.error(message, options={})
        return unless @@level <= LEVEL_ERROR
        print message, {level: "ERROR", caller: caller}.merge(options)
      end

      def self.print(message, options={})
        options[:level] ||= "PRINT"
        options[:caller] ||= caller

        caller_splat = options[:caller][0].split(":")
        ruby_file = caller_splat[0].split("/").last
        ruby_line = caller_splat[1]
        ruby_method = caller_splat[2].match(/`(.*)'/)[1]

        puts "%-10s%-30s%-30s%s" % ["[#{options[:level]}]", "#{ruby_file}:#{ruby_line}", ruby_method, message.encode("UTF-8")]
      end

    end
  end
end
