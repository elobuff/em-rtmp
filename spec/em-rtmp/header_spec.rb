require "spec_helper"

module EventMachine::RTMP

describe Header do

  let :io do
    Nutsack::Buffer.new
  end

  let :header do
    Header.new.tap do |h|
      h.channel_id = 44
      h.timestamp = 60000
      h.body_length = 12345
      h.message_type_id = 3
      h.message_stream_id = 100000
    end
  end

  it 'writes the proper length header' do
    [1,4,8,12].each do |size|
      header.header_length = size
      header.encode.length.should eql size
    end
  end

  it 'reads back idential data' do
    string = header.encode
    stream = Buffer.new string
    subject = Header.read_from_connection(stream)
    header.channel_id.should eql subject.channel_id
    header.timestamp.should eql subject.timestamp
    header.body_length.should eql subject.body_length
    header.message_type_id.should eql subject.message_type_id
    header.message_stream_id.should eql subject.message_stream_id
  end

  it 'reads the stream id' do
    stream = Buffer.new "\xc3"
    Header.read_from_connection(stream).channel_id.should eql 3
  end

  it 'can merge the values of another' do
    h1 = Header.new timestamp: 1, channel_id: 2, message_type_id: 3, message_stream_id: 4
    h2 = Header.new
    h2 += h1
    h2.channel_id.should eql 2
    h2.message_stream_id.should eql 4
  end

  describe 'with mock data' do

    it 'can parse a header with a single byte channel id' do
      stream = Buffer.new
      stream.write_bitfield [0b11, 2], [0, 6]
      stream.write_uint8 1
      stream.seek 0
      header = Header.read_from_connection(stream)
      header.channel_id.should eql (64+1)
    end

    it 'can parse a header with a two byte channel id' do
      stream = Buffer.new
      stream.write_bitfield [0b11, 2], [1, 6]
      stream.write_uint8 3
      stream.write_uint8 4
      stream.seek 0
      header = Header.read_from_connection(stream)
      header.channel_id.should eql (3 + 64 + (4 * 256))
    end

    it 'can parse a header with an extended timestamp' do
      timestamp = Time.now.to_i
      stream = Buffer.new
      stream.write_bitfield [0b10, 2], [4, 6]
      stream.write_uint24_be 0xffffff
      stream.write_uint32_be timestamp
      stream.pos = 0
      header = Header.read_from_connection(stream)
      header.timestamp.should eql timestamp
    end

    it 'parses a connect response' do
      stream = Buffer.new "\x03\x00\x00\x00\x00\x01\x05\x14\x00\x00\x00\x00"
      header = Header.read_from_connection(stream)
      header.channel_id.should eql 3
      header.message_type_id.should eql 20
      header.body_length.should eql 261
    end

  end

end
end
