module EventMachine
  module RTMP
    module IOHelpers

      # Read a unsigned 8-bit integer
      #
      # Returns the result of the read
      def read_uint8
        read_safe(1).unpack('C')[0]
      end

      # Write an unsigned 8-bit integer
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_uint8(value)
        write [value].pack('C')
      end

      # Read a unsigned 16-bit integer
      #
      # Returns the result of the read
      def read_uint16_be
        read_safe(2).unpack('n')[0]
      end

      # Write an unsigned 16-bit integer
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_uint16_be(value)
        write [value].pack('n')
      end

      # Read a unsigned 24-bit integer
      #
      # Returns the result of the read
      def read_uint24_be
        ("\x00" + read_safe(3)).unpack('N')[0]
      end

      # Write an unsigned 24-bit integer
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_uint24_be(value)
        write [value].pack('N')[1,3]
      end

      # Read a unsigned 32-bit integer (big endian)
      #
      # Returns the result of the read
      def read_uint32_be
        read_safe(4).unpack('N')[0]
      end

      # Read a unsigned 32-bit integer (little endian)
      #
      # Returns the result of the read
      def read_uint32_le
        read_safe(4).unpack('V')[0]
      end

      # Write an unsigned 32-bit integer (big endian)
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_uint32_be(value)
        write [value].pack('N')
      end

      # Write an unsigned 32-bit integer (big endian)
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_uint32_le(value)
        write [value].pack('V')
      end

      # Read a double (big endian)
      #
      # Returns the result of the read
      def read_double_be
        read_safe(8).unpack('G')[0]
      end

      # Write a double (big endian)
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_double_be(value)
        write [value].pack('G')
      end

      # Read an int29
      #
      # Returns the result of the stream operation
      def read_int29
        count = 1
        result = 0
        byte = read_uint8

        while (byte & 0x80 != 0) && count < 4 do
          result <<= 7
          result |= (byte & 0x7f)
          byte = read_uint8
          count += 1
        end

        if count < 4
          result <<= 7
          result |= byte
        else
          result <<= 8
          result |= byte
        end

        result
      end

      # Write an int29
      #
      # value - Value to write
      #
      # Returns the result of the stream operation
      def write_int29(value)
        value = value & 0x1fffffff
        if(value < 0x80)
          result = [value].pack('c')
          write result
        elsif(value < 0x4000)
          result = [value >> 7 & 0x7f | 0x80].pack('c') + [value & 0x7f].pack('c')
          write result
        elsif(value < 0x200000)
          result = [value >> 14 & 0x7f | 0x80].pack('c') + [value >> 7 & 0x7f | 0x80].pack('c') + [value & 0x7f].pack('c')
          write result
        else
          result = [value >> 22 & 0x7f | 0x80].pack('c') + [value >> 15 & 0x7f | 0x80].pack('c') + [value >> 8 & 0x7f | 0x80].pack('c') + [value & 0xff].pack('c')
          write result
        end
      end

      # Read a bit field and return the mapped results
      #
      # widths - Array of integers representing the size of the fields
      #
      # Returns the value for each field read
      def read_bitfield(*widths)
        byte = read_uint8
        shifts_and_masks(widths).map{ |shift, mask|
          (byte >> shift) & mask
        }
      end

      # Write a bit field to the stream
      #
      # values_and_widths - An array of arrays, each containing two values:
      #                       [0] - value to be written
      #                       [1] - width of value
      #
      # Returns the value for each field read
      def write_bitfield(*values_and_widths)
        sm = shifts_and_masks(values_and_widths.map{ |_,w| w })
        write_uint8 values_and_widths.zip(sm).inject(0){ |byte, ((value, width), (shift, mask))|
          byte | ((value & mask) << shift)
        }
      end

      def read_safe(length)
        raise ArgumentError, "cannot read nothing: #{length}" unless length && length >= 1

        if value = read(length)
          return value
        else
          Logger.error "unable to read from socket, closing connection"
          close_connection
          ""
        end
      end

      private

      # Obtain the shift and bitmasks for a set of widths
      #
      # Returns an array of arrays, each top-level array containing
      # two values:
      #   [0] - shift
      #   [1] - mask
      def shifts_and_masks(bit_widths)
        (0 ... bit_widths.length).map{ |i| [
          bit_widths[i+1 .. -1].inject(0){ |a,e| a + e },
          0b1111_1111 >> (8 - bit_widths[i])
        ]}
      end

    end
  end
end
