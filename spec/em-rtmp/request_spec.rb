require "spec_helper"

module EventMachine::RTMP

describe Request do

  let :request do
    c = Connection.new(nil)
    c.chunk_size = 128
    r = Request.new(c)
    r.header.channel_id = 3
    r.header.message_type_id = 17
    r.body = "WOOF" * 128
    r
  end

  it 'updates the header body length' do
    request.update_header
    request.header.body_length.should eql request.body.length
  end

  it 'should get the chunk size by the connection' do
    request.chunk_size.should eql 128
  end

  it 'should calculate the chunk size' do
    request.chunk_count.should eql 4
    request.body << "W" * 128
    request.chunk_count.should eql 5
  end

  it 'should keep a list of chunks' do
    request.chunks.should be_an_instance_of(Array)
    request.chunks.length.should eql request.chunk_count
  end

  it 'should determine the header length for a chunk' do
    request.header_length_for_chunk(0).should eql 12
    request.header_length_for_chunk(2).should eql 1
  end

  describe 'sending' do

    it 'updates the header' do
      request.stub(:send_chunk).and_return(129)
      request.should_receive(:update_header)
      request.send
    end

    it 'sends the right number of chunks' do
      request.stub(:send_chunk).and_return(129)
      request.should_receive(:send_chunk).exactly(request.chunk_count).times
      request.send
    end
  end

  describe 'sending a chunk' do
    it 'writes a header and a body' do
      request.update_header
      request.stub(:write).and_return(129)
      request.should_receive(:write).exactly(2).times
      request.send_chunk(request.chunks.first)
    end

    it 'returns the number of bytes written' do
      request.update_header
      request.stub(:write).and_return(129)
      request.send_chunk(request.chunks.first).should eql (129 * 2)
    end
  end

end

end
