module EventMachine
  module RTMP
    class UUID
      def self.random
        [8,4,4,4,12].map {|n| rand_hex_3(n)}.join('-').to_s.upcase
      end

      def self.rand_hex_3(l)
        "%0#{l}x" % rand(1 << l*4)
      end
    end
  end
end
