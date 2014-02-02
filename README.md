# EM-RTMP

[![Build Status](https://secure.travis-ci.org/elobuff/em-rtmp.png?branch=master)](http://travis-ci.org/elobuff/em-rtmp)

Asynchronous RTMP client powered by EventMachine.

## Usage

```ruby
require "em-rtmp"
# Start the EventMachine
EventMachine.run do

  # Establish a connection
  connection = EventMachine::RTMP.connect 'flashserver.bigmediacompany.com'

  # Issue an RTMP connect after the RTMP handshake
  connection.on_handshake_complete do
    EventMachine::RTMP::ConnectRequest.new(connection).send
  end

  # After the RTMP connect succeeds, continue on
  connection.on_ready do
    ...
  end

end
```

## License

MIT License, see LICENSE for details.
