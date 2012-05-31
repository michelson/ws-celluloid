# encoding: utf-8

require "socket"
require "libwebsocket"
#require 'celluloid'
#require 'celluloid/io'
#require 'dcell'
#require "libwebsocket"
require 'benchmark'


class WebSocket

  def initialize(url, params = {})
    @hs ||= LibWebSocket::OpeningHandshake::Client.new(:url => url, :version => params[:version])
    @frame ||= LibWebSocket::Frame.new

    @socket = TCPSocket.new(@hs.url.host, @hs.url.port || 80)

    @socket.write(@hs.to_s)
    @socket.flush

    loop do
      data = @socket.getc
      next if data.nil?

      result = @hs.parse(data.chr)

      raise @hs.error unless result

      if @hs.done?
        @handshaked = true
        break
      end
    end
  end

  def send(data)
    raise "no handshake!" unless @handshaked

    data = @frame.new(data).to_s
    @socket.write data
    @socket.flush
  end

  def receive
    raise "no handshake!" unless @handshaked

    data = @socket.gets("\xff")
    @frame.append(data)

    messages = []
    while message = @frame.next
      messages << message
    end
    messages
  end

  def socket
    @socket
  end

  def close
    @socket.close
  end

end


ws = WebSocket.new("ws://localhost:8080", {:resource_name => '/demo', :version=>"0.0.0"})




=begin
class EchoClient
  include Celluloid::IO

  def initialize(host, port)
    puts "*** Connecting to echo server on #{host}:#{port}"

    @socket = TCPSocket.from_ruby_socket(::TCPSocket.new(host, port))
  end

  def echo(s)
    @socket.write(s)
    actor = Celluloid.current_actor
    @socket.readpartial(4096)
  end

end
client = EchoClient.new("127.0.0.1", 8080)
client.echo("TEST FOR ECHO")
=end
=begin
n = 1000
Benchmark.bm do |x|
  #x.report { for i in 1..n; a = "1"; end }
  #x.report { n.times do   ; a = "1"; end }
  #x.report { 1.upto(n) do ; a = "1"; end }
  x.report {n.times do   ;  client.echo("TEST FOR ECHO") ; end }
  #user     system      total        real
  #0.390000   0.070000   0.460000 (  0.615671)
end
=end