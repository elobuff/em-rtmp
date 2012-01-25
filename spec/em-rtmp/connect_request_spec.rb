require "spec_helper"

module EventMachine::RTMP

describe ConnectRequest do

  let :request do
    ConnectRequest.new(Connection.new(nil))
  end

  it 'merges attributes and defaults into parameters' do
    request.parameters.should be_an_instance_of(Hash)
    request.parameters[:app].should eql ""
    request.app = "some_app"
    request.parameters[:app].should eql "some_app"
  end

  it 'should use the parameters as the value of the message' do
    request.stub(:send_chunk).and_return(0)
    request.send
    request.message.values.should eql [request.parameters]
  end

  it 'should use the encoded message as the body' do
    request.stub(:send_chunk).and_return(0)
    request.send
    request.body.should eql request.message.encode
  end

end

end
