require "rubygems"
require "bundler/setup"
require "em-rtmp"

def rescue_block(&blk)
  blk.call rescue nil
end

module EventMachine
  module RTMP
    class Logger
      def self.log(l, m); end
      def self.debug(m); end
      def self.info(m); end
      def self.error(m); end
      def self.print(m, o={}); end
    end
  end
end
