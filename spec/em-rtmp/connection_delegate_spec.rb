require "spec_helper"

module EventMachine::RTMP

describe ConnectionDelegate do

  let :delegate do
    c = Connection.new(nil)
    c.stub(:read).and_return("Data")
    c.stub(:write).and_return(1)
    c.stub(:bytes_waiting).and_return(8)
    ConnectionDelegate.new(c)
  end

  it 'delegates read operations to the connection' do
    delegate.read(4).should eql "Data"
  end

  it 'delegates write operations to the connection' do
    delegate.write("ARF").should eql 1
  end

  it 'returns the number of bytes waiting' do
    delegate.bytes_waiting.should eql 8
  end

  it 'maintains state' do
    delegate.change_state :fire
    delegate.state.should eql :fire
  end

end

end
