
class Server
  include Celluloid::IO

  def initialize(host, port, &callback)
    # This is actually an evented Celluloid::IO::TCPServer
    @server = TCPServer.new(host, port)
    @callback = Callback.new
    @callback.onopen do |ws| 
      @connections += 1
      puts "*** #{@connections} Open connections"
      @websockets[ws.request['path']] = ws 
    end
    @callback.onmessage do |ws, msg|
      ##puts @websockets.inspect
      puts "MESSAGE: #{msg}"
      ws.send("Did you say: '#{msg}', sir?")
    end
    @callback.onerror{|ws, err| 
      puts "ERROR: #{err}" 
    }
    @callback.onclose{|ws, err| 
      @connections -= 1 unless connections.zero?
      puts "*** #{@connections} Open connections"
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

