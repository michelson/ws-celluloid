
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
      puts "MESSAGE IN: #{msg}"
      #ws.send("Did you say: '#{msg}', sir?")
      begin
      send_messages_to_sockets(msg, ws.request['path'])
      rescue =>e
        puts e.message
      end
    end
    @callback.onerror{|ws, err| 
      puts "ERROR: #{err}" 
    }
    @callback.onclose{|ws, err| 
      @connections -= 1 unless connections.zero?
      remove_sockets(ws)
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
    # By now we'll be back in a :clean state!
    # begin
    #    puts "We should now be in a clean state again: #{supervisor.actor.state}"
    # rescue Celluloid::DeadActorError
    # Perhaps we got ahold of the actor before the supervisor restarted it
    #retry
    #  end
  rescue EOFError
    puts "WASS?"
    # finalize
    # Client disconnected prematurely
    # FIXME: should probably do something here
  end

  def notify(target, message)
    begin
      puts "NOTIFY: #{target} - #{message}"
      ws = @websockets["/#{target}"]
      unless ws.nil?
        puts "#{ws.size} socket connections"
        #ws && ws.send(message)
        ws.each{ |w| w.send(message) }
      end
    rescue => e
      puts e.message
    end
  end
  
  def send_messages_to_sockets(msg, path)
    #@websockets[path].each .... # add this if you want emit to channels only
    
    #emit messages to all channels & to each socket client
    @websockets.keys.each do |w| 
      @websockets[w].each do |o|
        #puts o.inspect
        puts "MESSAGE OUT: #{msg} to #{w}"
        begin
          o.send(msg)
        rescue Exception => e
          puts "Error sending menssages to sockets: #{e}"
        end
      end
    end
  end
  
  def refresh_sockets(ws)
    # adds sockets instances 
    @websockets[ws.request['path']].nil? ? @websockets[ws.request['path']] = [ws] : @websockets[ws.request['path']] << ws  
  end
  
  def remove_sockets(ws)
    # removes socket instances to avoid Mailbox errors
    @websockets[ws.request['path']].delete(ws)  unless @websockets[ws.request['path']].nil?
  end

end

