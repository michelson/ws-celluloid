// we made this simple library to not have to deal with
// complex implementations of websocket

var RhybooWS = {
	error: "Your browser does not support native web sockets"
}

if ("WebSocket" in window) {

	RhybooWS = function (options) {
		this.handlers = {};
		this._emptyfn = function() {};
		this.host = options.host || "localhost";
		this.port = options.port || 80;
		this._ws_servers = options.ws_servers || [];
		this._options = options || {};
		this._onopen = this._options.onOpen || this._emptyfn;
		this._onclose = this._options.onClose || this._emptyfn;
		this._onmessage = this._options.onMessage || this._emptyfn;		
		this._reconnect_interval = undefined;
		this._reconnection_time = this._options._reconnection_time || 1000;
		this._socket = {};
	}

	RhybooWS.fn = RhybooWS.prototype;

	RhybooWS.fn.connect = function() {
		this._reconnect = typeof this._options.reconnect == "boolean" ? this._options.reconnect : true;
		if (!this._socket.readyState || this._socket.readyState == WebSocket.CLOSED) {
			var server = {host:this.host, port: this.port};
			if(this._ws_servers.length) {
				server = this._ws_servers[Math.floor(Math.random()*this._ws_servers.length)];
			}
			this._socket = new WebSocket("ws://" + server.host + ":" + server.port);
			this._socket.onopen = function() {
				self._onopen();
			}
			var self = this;
			this._socket.onclose = function () {
				self._onclose();
				// should
				if (self._reconnect) {
					setTimeout(function() {
						self.connect();
					}, self._reconnection_time);
				}
			}
			// the router
			this._socket.onmessage = function(event) {
			  var message = JSON.parse(event.data);
			  if (self._options.onmessage) {self._options.onmessage(message)};
			  if (!message.channels) return;
			  message.channels.forEach(function(channel) {
			  	var handlers = self.handlers[channel];
			  	if (handlers) {
			  		handlers.forEach(function(handler) {handler(message.data)});
			  	}
			  });
			} // end onmessage
		} // end if (!this._)
		return this;
	};

	RhybooWS.fn.subscribe = function(channel, callback) {
		if (!channel) throw "Must provide a channel";
		if (!callback) throw "Must provide a callback";
		if (!this.handlers[channel]) this.handlers[channel] = [];
		this.handlers[channel].push(callback);
		return this;
	};

	RhybooWS.fn.unsubscribe = function(channel) {
	  if (!channel) throw "Must provide a channel";
	  if (this.handlers) { delete this.handlers[channel]; }
	  return this;
	};

	RhybooWS.fn.disconnect = function() {
		if (this._socket.readyState != WebSocket.CLOSED) {
			this._reconnect = false;
			this._socket.close();
		}
		return this;
	}
}
window.RhybooWS = RhybooWS;