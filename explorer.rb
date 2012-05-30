require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell/explorer'
DCell.start
DCell::Explorer.new("localhost", 8000)

while true
  sleep 1
end