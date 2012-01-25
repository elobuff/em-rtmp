require "rubygems"
require "bundler/setup"
require "em-rtmp"

def rescue_block(&blk)
  blk.call rescue nil
end

module EventMachine
  module RTMP
    class Logger
      def self.debug(m, o=nil); end
      def self.info(m, o=nil); end
      def self.error(m, o=nil); end
      def self.print(m, o=nil); end
    end
  end
end
