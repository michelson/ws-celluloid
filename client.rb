require 'celluloid'
require 'dcell'

ENV['PORT'] ||= '9234'
ENV['DCELL_PORT'] ||= (ENV['PORT'].to_i + 1).to_s
DCell.start :addr => "tcp://127.0.0.1:#{ENV['DCELL_PORT']}", :id => "id-#{ENV['DCELL_PORT']}", :registry => {
    :adapter => 'redis',
    :host => '127.0.0.1',
    :port => 6379
  }

puts "started dcell"
loop {
  Kernel.sleep(3)
  server = DCell::Global[:websockets]
  puts "sending notification"
  server.notify!("Channel", "notification from ruby")
  Kernel.sleep(3)
  server.notify!("Channel/one", "notification from ruby 2")
  Kernel.sleep(3)
  server.notify!("Channel/two", "notification from ruby 2")
  
  
}
puts "done sending"