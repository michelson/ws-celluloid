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
    
## bench
  
     node ./wsbench -c 2000 -r 50 ws://localhost:8083
     time ./wsbench -c 2000 -r 50 ws://localhost:8083
 
     > time ./wsbench -c 6000 -r 50 ws://localhost:8083
     Success rate: 100% from 6000 connections
     5.96s user 
     1.87s system 
     6% cpu 
     2:00.13 total
     
     # 1.9.3
     time ./wsbench -c 60000 -r 600 ws://localhost:8083
     Success rate: 51.1% from 60000 connections
     ./wsbench -c 60000 -r 600 ws://localhost:8083  
     33.18s user 
     7.97s system 
     40% cpu 
     1:40.95 total

## HAPROXY readings

+ http://catchvar.com/nodejs-server-and-web-sockets-on-amazon-ec2-w

+ http://jfarcand.wordpress.com/2011/10/06/configuring-haproxy-for-websocket/

+ http://stackoverflow.com/questions/8662377/haproxy-and-socket-io-not-fully-working 

+ GOOD: http://stackoverflow.com/questions/4360221/haproxy-websocket-disconnection
