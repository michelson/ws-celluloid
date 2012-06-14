
(function() {
	
	
	var debug;
  debug = function(string, div) {
    if (div == null) {
      div = "debug";
    }
    var element = document.getElementById(div);
    var p = document.createElement("p");
    p.appendChild(document.createTextNode(string));
    element.appendChild(p);
  };
	
  var App;
  App = {};
  /*
  	Init 
  */
  App.init = function() {
    App.canvas = document.createElement('canvas');
    App.canvas.height = 400;
    App.canvas.width = 800;
    document.getElementsByTagName('article')[0].appendChild(App.canvas);
    App.ctx = App.canvas.getContext("2d");
    App.ctx.fillStyle = "solid";
    App.ctx.strokeStyle = "#ECD018";
    App.ctx.lineWidth = 5;
    App.ctx.lineCap = "round";
    
		//App.socket = io.connect('http://localhost:4000');
    //App.socket.on('draw', function(data) {
    //  return App.draw(data.x, data.y, data.type);
    //});


    App.draw = function(x, y, type) {
			//console.log(x,y,type);
      if (type === "dragstart") {
        App.ctx.beginPath();
        return App.ctx.moveTo(x, y);
      } else if (type === "drag") {
        App.ctx.lineTo(x, y);
        return App.ctx.stroke();
      } else {
        return App.ctx.closePath();
      }
    };


		//var Socket, ws;
    Socket = ("MozWebSocket" in window ? MozWebSocket : WebSocket);
    
    App.ws = new Socket("ws://localhost:3000/Channel");
    
    console.log(App.ws);
    
    App.ws.onmessage = function(evt) {
      //console.log(evt)
			try {
				var draw_data = JSON.parse(evt.data);
	      debug("Message: " +  draw_data.x + " " + draw_data.y + " " + draw_data.type );
				return App.draw(draw_data.x, draw_data.y, draw_data.type);
			} catch(err) {
				//debug("no json parsing, process string instead " + evt.data  );
				debug(evt.data , "status_debug");
			}

    };
    App.ws.onclose = function() {
      var t;
      debug("socket closed", "status");
      //return t = setTimeout("createWs()", 3000);
    };
    App.ws.onopen = function() {
      debug("connected...", "status");
      //App.ws.send("hello server");
      //return App.ws.send("hello again");
    };

  };
  /*
  	Draw Events
  */
  $('canvas').live('drag dragstart dragend', function(e) {
    var offset, type, x, y;
    type = e.handleObj.type;
    offset = $(this).offset();
    e.offsetX = e.layerX - offset.left;
    e.offsetY = e.layerY - offset.top;
    x = e.offsetX;
    y = e.offsetY;
    //App.draw(x, y, type);
		data = JSON.stringify({"x":x, "y":y, "type":type});
    App.ws.send(data);
  });

  $(function() {
    return App.init();
  });

}).call(this);
