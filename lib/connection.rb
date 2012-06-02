class Connection
  attr_writer :max_frame_size
  BUFFER_SIZE = 4096

  def trigger_on_message(msg)
    @callback.trigger_on_message(self, msg)
  end
  def trigger_on_open
    @callback.trigger_on_open(self)
  end
  def trigger_on_close
    @callback.trigger_on_close(self)
  end
  def trigger_on_ping(data)
    @callback.trigger_on_ping(self, data)
  end
  def trigger_on_pong(data)
    @callback.trigger_on_pong(self, data)
  end
  def trigger_on_error(reason)
    return @callback.trigger_on_error(self, reason)
  end

  def initialize(socket, callback)
    @data = ''
    @socket = socket
    @callback = callback
    puts "initialized connection"
  end

  def keep_reading
    receive_data(@socket.readpartial(BUFFER_SIZE)) while true
  rescue IOError, Errno::ECONNRESET, Errno::EPIPE
    @socket.close unless @socket.closed?
    begin
      @handler.unbind if @handler
    rescue => e
      puts [:error, e]
      # These are application errors - raise unless onerror defined
      trigger_on_error(e) || raise(e)
    end
    return
  end

  # Use this method to close the websocket connection cleanly
  # This sends a close frame and waits for acknowlegement before closing
  # the connection
  def close_websocket(code = nil, body = nil)
    if code && !(4000..4999).include?(code)
      raise "Application code may only use codes in the range 4000-4999"
    end

    # If code not defined then set to 1000 (normal closure)
    code ||= 1000

    close_websocket_private(code, body)
  end

  def receive_data(data)
    puts [:receive_data, data]

    if @handler
      @handler.receive_data(data.force_encoding("ASCII-8BIT"))
    else
      dispatch(data)
    end
  rescue EventMachine::WebSocket::HandshakeError => e
    puts "HandshakeError"
    puts [:error, e]
    trigger_on_error(e)
    # Errors during the handshake require the connection to be aborted
    abort
  rescue EventMachine::WebSocket::WSProtocolError => e
    puts "WSProtocolError"
    puts [:error, e]
    trigger_on_error(e)
    close_websocket_private(e.code)
  rescue => e
    puts [:error, e]
    # These are application errors - raise unless onerror defined
    trigger_on_error(e) || raise(e)
    # There is no code defined for application errors, so use 3000
    # (which is reserved for frameworks)
    close_websocket_private(3000)
  end

  def dispatch(data)
    if data.match(/\A<policy-file-request\s*\/>/)
      send_flash_cross_domain_file
      return false
    else
      puts [:inbound_headers, data]
      @data << data
      @handler = HandlerFactory.build(self, @data)
      unless @handler
        # The whole header has not been received yet.
        return false
      end
      @data = nil
      @handler.run
      return true
    end
  end

  def send_flash_cross_domain_file
    file = '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>'
    puts [:cross_domain, file]
    @socket << file

    # handle the cross-domain request transparently
    # no need to notify the user about this connection
    @onclose = nil
    @socket.close
  end

  def send(data)
    # If we're using Ruby 1.9, be pedantic about encodings
    if data.respond_to?(:force_encoding)
      # Also accept ascii only data in other encodings for convenience
      unless (data.encoding == Encoding.find("UTF-8") && data.valid_encoding?) || data.ascii_only?
        raise WebSocketError, "Data sent to WebSocket must be valid UTF-8 but was #{data.encoding} (valid: #{data.valid_encoding?})"
      end
      # This labels the encoding as binary so that it can be combined with
      # the BINARY framing
      data.force_encoding("BINARY")
    else
      # TODO: Check that data is valid UTF-8
    end

    if @handler
      @handler.send_text_frame(data)
    else
      raise WebSocketError, "Cannot send data before onopen callback"
    end
    
  rescue Execption => e
    puts "End of stream here, Closing connections!!! #{e.message}"
    close_connection_after_writing
  end

  # Send a ping to the client. The client must respond with a pong.
  #
  # In the case that the client is running a WebSocket draft < 01, false
  # is returned since ping & pong are not supported
  #
  def ping(body = '')
    if @handler
      @handler.pingable? ? @handler.send_frame(:ping, body) && true : false
    else
      raise WebSocketError, "Cannot ping before onopen callback"
    end
  end

  # Send an unsolicited pong message, as allowed by the protocol. The
  # client is not expected to respond to this message.
  #
  # em-websocket automatically takes care of sending pong replies to
  # incoming ping messages, as the protocol demands.
  #
  def pong(body = '')
    if @handler
      @handler.pingable? ? @handler.send_frame(:pong, body) && true : false
    else
      raise WebSocketError, "Cannot ping before onopen callback"
    end
  end

  # Test whether the connection is pingable (i.e. the WebSocket draft in
  # use is >= 01)
  def pingable?
    if @handler
      @handler.pingable?
    else
      raise WebSocketError, "Cannot test whether pingable before onopen callback"
    end
  end

  def request
    @handler ? @handler.request : {}
  end

  def state
    @handler ? @handler.state : :handshake
  end

  # Returns the maximum frame size which this connection is configured to
  # accept. This can be set globally or on a per connection basis, and
  # defaults to a value of 10MB if not set.
  #
  # The behaviour when a too large frame is received varies by protocol,
  # but in the newest protocols the connection will be closed with the
  # correct close code (1009) immediately after receiving the frame header
  #
  def max_frame_size
    @max_frame_size || EventMachine::WebSocket.max_frame_size
  end

  def close_connection_after_writing
    close_connection
  end

  def close_connection
    @socket.close
  end

  def send_data(data)
    @socket << data
  end


  private



  # As definited in draft 06 7.2.2, some failures require that the server
  # abort the websocket connection rather than close cleanly
  def abort
    close_connection
  end

  def close_websocket_private(code, body = nil)
    if @handler
      puts [:closing, code]
      @handler.close_websocket(code, body)
    else
      # The handshake hasn't completed - should be safe to terminate
      abort
    end
  end
end
