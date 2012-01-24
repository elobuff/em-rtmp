require "em-rtmp/connection_delegate"

module EventMachine
  module RTMP
    class Handshake < ConnectionDelegate

      # The RTMP handshake involes each party sending 3 packets of data.
      #
      # Client                                Server
      # --------------------------------------------
      # 0x03 ->
      # 1536 random bytes (a) ->
      #                                      <- 0x03
      #                     <- 1536 random bytes (b)
      # b ->
      #                                         <- a
      #
      # The handshake is completed by verifying that the response received
      # matches the challenge string, with the notable exception that the
      # first 4 bytes may be used for timestamping and can be different, and
      # the second 4 bytes must all be zero.

      HANDSHAKE_VERSION = 0x03
      HANDSHAKE_LENGTH = 1536

      # Handles a change to the buffer state
      #
      # Returns a symbol indicating our state
      def buffer_changed
        Logger.print "#{state} #{bytes_waiting}", indent: 1
        case state
        when :challenge_issued
          if bytes_waiting >= (1 + HANDSHAKE_LENGTH)
            handle_server_challenge
          end
        when :challenge_received
          if bytes_waiting >= HANDSHAKE_LENGTH
            handle_server_response
          end
        else
          raise HandshakeError, "Reached unexpected state"
        end

        state
      end

      # Send the version byte followed by our challenge
      #
      # Returns a state update
      def issue_challenge
        Logger.print "issuing client challenge", indent: 1

        @client_challenge = "\x00\x00\x00\x00\x00\x00\x00\x00" + (8...HANDSHAKE_LENGTH).map{rand(255)}.pack('C*')

        write_uint8 HANDSHAKE_VERSION
        write @client_challenge

        change_state :challenge_issued
      end

      # Receives the server version byte and reissues it to the stream
      #
      # Returns a state update
      def handle_server_challenge
        Logger.print "handling server challenge", indent: 1

        server_version = read_uint8
        unless server_version == HANDSHAKE_VERSION
          raise HandshakeError, "Expected version byte to be 0x03"
        end

        server_challenge = read(HANDSHAKE_LENGTH)
        write server_challenge
        change_state :challenge_received
      end

      # Reads the server response to our challenge to authenticate peer
      #
      # Returns a state update
      def handle_server_response
        Logger.print "handling client response", indent: 1

        server_response = read(HANDSHAKE_LENGTH)
        unless server_response == @client_challenge
          raise HandshakeError, "Expected server to return client challenge"
        end

        Logger.print "handshake complete", indent: 1
        change_state :handshake_complete
      end

    end
  end
end
