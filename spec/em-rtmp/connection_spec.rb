require "spec_helper"

module EventMachine::RTMP

describe Connection do
  let :connection do
    Connection.new(nil)
  end

  it "runs callbacks on state change" do
    connection.stub(:run_callbacks)
    connection.should_receive(:run_callbacks).with(:ready)
    connection.change_state(:ready)
  end

  it "write operation should send data to EM" do
    connection.stub(:send_data)
    connection.should_receive(:send_data)
    connection.write('hi')
  end

  it "begins rtmp handshake on successful connection" do
    connection.stub(:begin_rmtp_handshake)
    connection.should_receive(:begin_rtmp_handshake)
    connection.connection_completed
  end

  it "changes state to disconnected on unbind" do
    connection.should_receive(:change_state).with(:disconnected)
    connection.unbind
  end

  it "should trigger a buffer change on receive data" do
    connection.should_receive(:buffer_changed)
    connection.receive_data("X")
  end
end

describe SecureConnection do
  let :connection do
    SecureConnection.new(nil)
  end

  it "starts tls on successful connection" do
    connection.stub(:start_tls)
    connection.should_receive(:start_tls)
    connection.connection_completed
  end

  it "begins rtmp handshake on successful ssl handshake" do
    connection.stub(:begin_rmtp_handshake)
    connection.should_receive(:begin_rtmp_handshake)
    connection.ssl_handshake_completed
  end
end

end
