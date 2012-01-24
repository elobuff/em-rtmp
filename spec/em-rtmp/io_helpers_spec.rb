require "spec_helper"

module EventMachine::RTMP

describe IOHelpers do

  let :buffer do
    Buffer.new
  end

  describe 'reads data' do

    it 'as uint8' do
      buffer.string = [5].pack('c')
      result = buffer.read_uint8
      result.should be_an_instance_of(Fixnum)
      result.should eql 5
    end

    it 'as uint16 (big endian)' do
      buffer.string = [16000].pack('n')
      result = buffer.read_uint16_be
      result.should be_an_instance_of(Fixnum)
      result.should eql 16000
    end

    it 'as uint24 (big endian)' do
      buffer.string = [70000].pack('N')[1,3]
      result = buffer.read_uint24_be
      result.should be_an_instance_of(Fixnum)
      result.should eql 70000
    end

    it 'as uint32 (big endian)' do
      buffer.string = [100000].pack('N')
      result = buffer.read_uint32_be
      result.should be_an_instance_of(Fixnum)
      result.should eql 100000
    end

    it 'as double (big endian)' do
      buffer.string = [10000000].pack('G')
      result = buffer.read_double_be
      result.should be_an_instance_of(Float)
      result.should eql 10000000.0
    end

  end

  describe 'writes data' do

    it 'writes uint8' do
      buffer.write_uint8 32
      buffer.length.should eql 1
      buffer.seek 0
      buffer.read_uint8.should eql 32
    end

    it 'writes uint16_be' do
      buffer.write_uint16_be 16000
      buffer.length.should eql 2
      buffer.seek 0
      buffer.read_uint16_be.should eql 16000
    end

    it 'writes uint24_be' do
      buffer.write_uint24_be 70000
      buffer.length.should eql 3
      buffer.seek 0
      buffer.read_uint24_be.should eql 70000
    end

    it 'writes uint32_be' do
      buffer.write_uint32_be 100000
      buffer.length.should eql 4
      buffer.seek 0
      buffer.read_uint32_be.should eql 100000
    end

    it 'writes uint32_le' do
      buffer.write_uint32_le 100000
      buffer.length.should eql 4
      buffer.seek 0
      buffer.read_uint32_le.should eql 100000
    end

    it 'writes double_be' do
      buffer.write_double_be 10000000
      buffer.length.should eql 8
      buffer.seek 0
      buffer.read_double_be.should eql 10000000.0
    end

    it 'writes int29' do
      buffer.write_int29 5000000
      buffer.length.should eql 4
      buffer.seek 0
      buffer.read_int29.should eql 5000000
    end

    it 'writes bitfields' do
      buffer.write_bitfield [3, 2], [10, 6]
      buffer.length.should eql 1
      buffer.seek 0
      val1, val2 = buffer.read_bitfield 2, 6
      val1.should eql 3
      val2.should eql 10
    end

  end

end

end
