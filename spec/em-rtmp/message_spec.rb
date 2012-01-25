require "spec_helper"

module EventMachine::RTMP

describe Message do

  let :message do
    Message.new
  end

  it 'is not successful if the command is _error' do
    message.command = '_error'
    message.success?.should be_false
  end

  it 'is not successful if an exception was encountered' do
    message._amf_error = "SOMETHING!"
    message.success?.should be_false
  end

  it 'is successful when the command is not _error and no exception was encountered' do
    message.command = '_result'
    message.success?.should be_true
  end

end

end
