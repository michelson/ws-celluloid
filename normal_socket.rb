require 'socket'
require "libwebsocket"

 # Server bind to port 2000
@server = TCPServer.new 8080

class Ws 
  
  def initialize()
    
    @hs ||= LibWebSocket::Handshake::Server.new
    @frame ||= LibWebSocket::Frame.new
  end
  
  def receive_data(data)
    puts data
    if !@hs.done?
      @hs.parse(data)
      if @hs.done?
        "DONE!"
      end
      return
    end

    @frame.append(data)

    while message = @frame.next
      send_data @frame.new(message).to_s
    end
  end
end

loop do
  @ws ||= Ws.new
  socket = @server.accept    # Wait for a client to connect
  
  socket.puts "Hello !"
  socket.puts "Time is #{Time.now}"
  
  
  _, port, host = socket.peeraddr
  puts "*** Received connection from #{host}:#{port}"
  begin
    socket.write @ws.receive_data(socket.readpartial(1024)) 
  rescue Exception => e
    puts e.message  
    puts e.backtrace
    socket.close
  end

  
end




