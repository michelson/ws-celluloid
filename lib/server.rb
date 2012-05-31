# encoding: utf-8

class Server
  
  include Celluloid::IO
  
  def initialize(host, port)
    @server = TCPServer.new(host, port)
    puts "*** Starting TCP server on #{host}:#{port}"
    run!
  end

  def finalize
    @server.close if @server
  end

  def run
    #@socket.run
    loop { handle_connection! @server.accept }
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
    #data = data.force_encoding('utf-8') #.encode('ASCII-8BIT', 'utf-8') #.encode("ASCII-16BIT")
    puts data
    @hs ||= LibWebSocket::OpeningHandshake::Server.new
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
      puts @frame.new(message).to_s
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

