require "spec_helper"

module EventMachine::RTMP

describe ResponseRouter do

  let :connection do
    Connection.new nil
  end

  let :header do
    Header.new header_length: 12, channel_id: 3, message_type_id: 17
  end

  let :response do
    r = Response.new 3, connection
    r.header.body_length = 55
    r
  end

  let :router do
    ResponseRouter.new connection
  end

  it "should default to the wait_header state" do
    router.state.should eql :wait_header
  end

  describe "receiving a header" do
    it "should find an appropriate response and receive the chunk" do
      router.stub(:receive_chunk)
      router.should_receive(:receive_chunk)
      router.receive_header(header)
    end
  end

  describe "receiving a chunk" do
    it "should read the next chunk" do
      response.stub(:read_next_chunk)
      response.should_receive(:read_next_chunk)
      router.receive_chunk(response)
    end

    it "should set the state to wait_chunk if the read wasnt complete" do
      response.stub(:read_next_chunk)
      response.stub(:waiting_in_chunk?).and_return(true)
      response.stub(:complete?).and_return(false)
      router.receive_chunk(response)
      router.state.should eql :wait_chunk
      router.active_response.should eql response
    end

    it "should set the state to wait_header if the read was complete" do
      response.stub(:read_next_chunk)
      response.stub(:waiting_in_chunk?).and_return(false)
      response.stub(:complete?).and_return(false)
      router.receive_chunk(response)
      router.state.should eql :wait_header
      router.active_response.should be_nil
    end

    it "routes and resets the response if it's complete" do
      response.stub(:read_next_chunk)
      response.stub(:waiting_in_chunk?).and_return(false)
      response.stub(:complete?).and_return(true)
      router.stub(:route_response)
      router.should_receive(:route_response)
      response.should_receive(:reset)
      router.receive_chunk(response)
    end
  end

end

end
