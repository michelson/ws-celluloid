
class WebSocketServer
  include Celluloid::IO
    def initialize(params_or_uri, params = nil)
      if params
        uri = params_or_uri.is_a?(String) ? URI.parse(params_or_uri) : params_or_uri
        params[:port] ||= uri.port
        params[:accepted_domains] ||= [uri.host]
      else
        params = params_or_uri
      end
      @port = params[:port] || 80
      @accepted_domains = params[:accepted_domains]
      puts @accepted_domain
      if !@accepted_domains
        raise(ArgumentError, "params[:accepted_domains] is required")
      end
      @tcp_server = TCPServer.new(params[:host] || "0.0.0.0", @port)
    end

    attr_reader(:tcp_server, :port, :accepted_domains)

    def run(&block)
      while true
          s = accept()
          begin
            ws = create_web_socket(s)
            yield(ws) if ws
          rescue => ex
            print_backtrace(ex)
          ensure
            begin
              ws.close_socket() if ws
            rescue
            end
          end
      end
    end

    def accept()
      return @tcp_server.accept()
    end

    def accepted_origin?(origin)
      domain = origin_to_domain(origin)
      return @accepted_domains.any?(){ |d| File.fnmatch(d, domain) }
    end

    def origin_to_domain(origin)
      if origin == "null" || origin == "file://" # local file
        return "null"
      else
        return URI.parse(origin).host
      end
    end

    def create_web_socket(socket)
      ch = socket.getc()
      if ch == ?<
        # This is Flash socket policy file request, not an actual Web Socket connection.
        send_flash_socket_policy_file(socket)
        return nil
      else
        socket.ungetc(ch) if ch
        return WebSocket.new(socket, :server => self)
      end
    end

  private

    def print_backtrace(ex)
      $stderr.printf("%s: %s (%p)\n", ex.backtrace[0], ex.message, ex.class)
      for s in ex.backtrace[1..-1]
        $stderr.printf(" %s\n", s)
      end
    end

    # Handles Flash socket policy file request sent when web-socket-js is used:
    # http://github.com/gimite/web-socket-js/tree/master
    def send_flash_socket_policy_file(socket)
      socket.puts('<?xml version="1.0"?>')
      socket.puts('<!DOCTYPE cross-domain-policy SYSTEM ' +
        '"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">')
      socket.puts('<cross-domain-policy>')
      for domain in @accepted_domains
        next if domain == "file://"
        socket.puts("<allow-access-from domain=\"#{domain}\" to-ports=\"#{@port}\"/>")
      end
      socket.puts('</cross-domain-policy>')
      socket.close()
    end

end