require "spec_helper"

module EventMachine::RTMP

describe Response do

  let :connection do
    Connection.new(nil)
  end

  let :response do
    r = Response.new(3, connection)
    r.header.body_length = 55
    r
  end

  it "should get the chunk size by the connection" do
    response.chunk_size.should eql 128
  end

  it "should know if it's complete" do
    response.header.body_length = 5
    response.body = ""
    response.complete?.should eql false
    response.body = "ALOHA"
    response.complete?.should eql true
  end

  describe "when starting a new chunk" do
    it "the max read size should be the lesser of body length or max chunk size" do
      response.header.body_length = 55
      response.read_size.should eql 55
      response.header.body_length = 350
      response.read_size.should eql 128
    end
  end

  describe "when continuing an existing chunk" do
    it "the max read size should be the bytes we're waiting on" do
      response.waiting_on_bytes = 55
      response.read_size.should eql 55
    end

    it "we should know that we're waiting in chunk" do
      response.waiting_on_bytes = 55
      response.waiting_in_chunk?.should eql true
    end
  end

  describe "reading data" do
    it "raises an error if the response is fully read" do
      response.header.body_length = 2
      response.body = "AA"
      lambda { response.read_next_chunk }.should raise_error
    end

    it "reads the read size" do
      response.stub(:read).and_return("ALOHA" * 11)
      response.should_receive(:read).with(response.read_size)
      response.read_next_chunk
    end

    it "handles a null read" do
      response.stub(:read).and_return(nil)
      lambda { response.read_next_chunk }.should_not raise_error
    end

    it "stores the read data in the body" do
      response.stub(:read).and_return("ALOHA")
      response.body.should eql ""
      response.read_next_chunk
      response.body.should eql "ALOHA"
    end

    it "remembers that it needs more bytes if the read is short" do
      response.header.body_length = 55
      response.body = ""
      response.stub(:read).and_return("ALOHA")
      response.read_next_chunk
      response.waiting_on_bytes.should eql 50
    end

    it "is not waiting on bytes if the read is in full" do
      response.stub(:read).and_return("ALOHA" * 11)
      response.read_next_chunk
      response.waiting_on_bytes.should eql 0
    end
  end

end

end
