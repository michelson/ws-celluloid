
class Server
  include Celluloid::IO

  def initialize(host, port, &callback)
    # This is actually an evented Celluloid::IO::TCPServer
    @server = TCPServer.new(host, port)
    @callback = Callback.new
    @callback.onopen do |ws| 
      @connections += 1
      puts "*** #{@connections} Open connections"
      #@websockets[ws.request['path']] = ws 
      refresh_sockets(ws)
    end
    @callback.onmessage do |ws, msg|
      #puts @websockets.inspect
      puts "MESSAGE: #{msg}"
      #ws.send("Did you say: '#{msg}', sir?")
      send_messages_to_sockets(msg, ws.request['path'])
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
    puts "#{ws.size} socket connections"
    #ws && ws.send(message)
    ws.each{ |w| w.send(message) }
  end
  
  def send_messages_to_sockets(msg, path)
    @websockets[path].each do |o| 
      begin
        o.send("Did you say: '#{msg}', sir?")
      rescue Exception => e
        puts "Error enviando mensajes a sockets: #{e}"
      end
    end
  end
  
  def refresh_sockets(ws)
    @websockets[ws.request['path']].nil? ? @websockets[ws.request['path']] = [ws] : @websockets[ws.request['path']] << ws  
  end

end

