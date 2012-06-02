
class Server
  include Celluloid::IO

  def initialize(host, port, &callback)
    # This is actually an evented Celluloid::IO::TCPServer
    @server = TCPServer.new(host, port)
    @callback = Callback.new
    @callback.onopen{|ws| 
      @connections += 1
      @websockets[ws.request['path']] = ws 
      }
    @callback.onmessage do |ws, msg|
      ##puts @websockets.inspect
      puts "MESSAGE: #{msg}"
      ws.send("Did you say: '#{msg}', sir?")
    end
    @callback.onerror{|ws, err| 
      @connections -= 1
      puts "ERROR: #{err}" 
    }

    @websockets = {}
    run!
  end

  def finalize
    @server.close
  end

  def run
    loop { handle_connection! @server.accept }
  end
  
  def connections
    @connections ||= 0
  end

  def handle_connection(socket)
    puts "CONNECTIONS: #{connections}"
    connection = Connection.new(socket, @callback)
    connection.keep_reading
  rescue EOFError
    # finalize
    # Client disconnected prematurely
    # FIXME: should probably do something here
  end

  def notify(target, message)
    puts "NOTIFY: #{target} - #{message}"
    ws = @websockets["/#{target}"]
    ws && ws.send(message)
  end

end

