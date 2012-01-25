require "spec_helper"

module EventMachine::RTMP

describe Handshake do

  let :connection do
    Connection.new(nil)
  end

  let :handshake do
    Handshake.new(connection)
  end

  describe 'initial challenge' do
    it 'writes the version and client challenge' do
      connection.stub(:write).and_return(1)
      handshake.should_receive(:write_uint8).with(0x03)
      handshake.should_receive(:write)
      handshake.issue_challenge
    end

    it 'changes state after issuing the challenge' do
      connection.stub(:write).and_return(1)
      handshake.should_receive(:change_state).with(:challenge_issued)
      handshake.issue_challenge
    end
  end

  describe 'handles server challenge' do
    it 'reads the version and server challenge, then writes it back' do
      connection.stub(:read).and_return(1)
      connection.stub(:write).and_return(1)
      handshake.stub(:read_uint8).and_return(0x03)
      handshake.should_receive(:read_uint8)
      handshake.should_receive(:read)
      handshake.should_receive(:write)
      handshake.handle_server_challenge
    end

    it 'raises an error if the version isnt right' do
      handshake.stub(:read_uint8).and_return(0x04)
      lambda { handshake.handle_server_challenge }.should raise_error
    end
  end

  describe 'handles server response' do
    it 'reads the response' do
      connection.stub(:read).and_return(1)
      handshake.should_receive(:read)
      rescue_block { handshake.handle_server_response }
    end
  end

end

end
