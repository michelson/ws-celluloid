# encoding: utf-8

class Server
  
  include Celluloid::IO
  
  def initialize(host, port)
    @server = WebSocketServer.new(:accepted_domains => host, :port => port) #TCPServer.new(host, port)
    puts "*** Starting TCP server on #{host}:#{port}"
    run!
  end

  def finalize
    @server.close if @server
  end

  def run
    #@socket.run
    #loop { handle_connection! @server.accept }
    @server.run() do |ws|
      puts("Connection accepted")
      puts("Path: #{ws.path}, Origin: #{ws.origin}")
      if ws.path == "/"
        ws.handshake()
        while data = ws.receive()
          printf("Received: %p\n", data)
          ws.send(data)
          printf("Sent: %p\n", data)
        end
      else
        ws.handshake("404 Not Found")
      end
      puts("Connection closed")
    end
  end
  
  def handle_connection(socket)
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    loop { 
      begin
        socket.write receive_data(socket.readpartial(1024)) 
      rescue Exception => e
        puts e.message  
        puts e.backtrace
        finalize
      end
      }
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
  end
  
  def receive_data(data)
    puts data
    @hs ||= LibWebSocket::Handshake::Server.new
    @frame ||= LibWebSocket::Frame.new

    if !@hs.done?
      @hs.parse(data)
      if @hs.done?
        send_data(@hs.to_s)
      end
      return
    end

    @frame.append(data)

    while message = @frame.next
      send_data @frame.new(message).to_s
    end
  end
 
end

# @private
# :nodoc:
# Taken from Zed Shaw's Mongrel
class TCPServer
  def initialize_with_backlog(*args)
    initialize_without_backlog(*args)
    listen(1024)
  end

  alias_method :initialize_without_backlog, :initialize
  alias_method :initialize, :initialize_with_backlog
end

