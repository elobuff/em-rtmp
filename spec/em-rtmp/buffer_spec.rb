require "spec_helper"

module EventMachine::RTMP

describe Buffer do

  let :buffer do
    Buffer.new "Lucky Bob"
  end

  it 'calculates the number of remaining bytes' do
    buffer.remaining.should eql 9
    buffer.read(4)
    buffer.remaining.should eql 5
  end

  it 'truncates and seeks to zero' do
    buffer.reset
    buffer.pos.should eql 0
    buffer.length.should eql 0
  end

  it 'appends without incrementing the pointer' do
    buffer.append ' Smith'
    buffer.pos.should eql 0
  end

end

end
