# Celluloid-io with em-websocket proof of concept 
## based on web3-celluloid repo

## DCell test

    
    tab1: bundle exec ruby process.rb 8087 websockets1
    tab2: bundle exec ruby process.rb 8083 websockets1
    tab3: bundle exec ruby pub.rb
    
  or
  
    foreman start
    
## html5 websocket

    open tests/index.html in browser
  
## Haproxy

    haproxy -f config/haproxy.cfg

## HAPROXY readings

+ http://catchvar.com/nodejs-server-and-web-sockets-on-amazon-ec2-w

+ http://jfarcand.wordpress.com/2011/10/06/configuring-haproxy-for-websocket/

+ http://stackoverflow.com/questions/8662377/haproxy-and-socket-io-not-fully-working 

+ GOOD: http://stackoverflow.com/questions/4360221/haproxy-websocket-disconnection
