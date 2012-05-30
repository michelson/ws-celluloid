# encoding: utf-8

#require 'addressable/uri'
require "libwebsocket"
require 'celluloid'
require 'celluloid/io'
require 'dcell'
require './lib/server'


CONFIG = YAML.load(open "config/config.yml")["development"]

port = CONFIG["server"]["port"] + 1
DCell.start :addr => "#{CONFIG["server"]["host"]}:#{port}", :id => "id-#{port}", 
:registry => {
  :adapter => CONFIG["adapter"]["type"],
    :host  => CONFIG["adapter"]["host"],
    :port  => CONFIG["adapter"]["port"]
}

supervisor = Server.supervise_as(:websockets, "0.0.0.0", CONFIG["server"]["port"].to_i)
DCell::Global[:websockets] = supervisor.actor
trap("INT") { supervisor.terminate; exit }
sleep

