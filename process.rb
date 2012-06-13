require 'addressable/uri'
require 'celluloid'
require 'celluloid/io'
require 'dcell'
require 'em-websocket'
require 'em-websocket/websocket'
require './lib/connection'
require './lib/callback'
require './lib/server'

HandlerFactory = EventMachine::WebSocket::HandlerFactory
CONFIG = YAML.load(open "config/config.yml")["development"]

port  = ARGV[0]
msg =  ARGV[1].to_sym || :websockets

## usage: bundle exec ruby process.rb 8087 websockets1

dport = port.to_i + 1
DCell.start :addr => "#{CONFIG["server"]["host"]}:#{dport}", :id => "id-#{dport}", 
:registry => {
  :adapter => CONFIG["adapter"]["type"],
    :host  => CONFIG["adapter"]["host"],
    :port  => CONFIG["adapter"]["port"]
}

#single process
supervisor = Server.supervise_as(msg, "0.0.0.0", port.to_i)
DCell::Global[msg] = supervisor.actor
trap("INT") { exit }
sleep