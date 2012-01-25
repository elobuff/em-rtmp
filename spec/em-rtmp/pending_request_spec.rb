require "spec_helper"

module EventMachine::RTMP

describe PendingRequest do

  let :request do
    r = Request.new(Connection.new(nil))
    r.header.message_type = :amf3
    r.message.transaction_id = 50.0
    r
  end

  it 'can create new pending requests' do
    PendingRequest.create(request).should be_an_instance_of(PendingRequest)
  end

  it 'finds the request with an integer transaction id' do
    PendingRequest.create(request)
    PendingRequest.find(:amf3, 50).should be_an_instance_of(PendingRequest)
  end

  it 'finds the request with a float transaction id' do
    PendingRequest.create(request)
    PendingRequest.find(:amf3, 50.0).should be_an_instance_of(PendingRequest)
  end

  it 'can delete itself when complete' do
    PendingRequest.create(request)
    req = PendingRequest.find(:amf3, 50)
    req.delete
    PendingRequest.find(:amf3, 50).should be_nil
  end

end

end
