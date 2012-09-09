Musubi.AMQPTransport = function(server, keyPair) {
	this._socket = null;
	this._keyPair = keyPair;
	this.init(server);
}

Musubi.AMQPTransport.prototype.init = function(server) {
	var thisTransport = this;
	this._listeners = []
	
	this._socket = new WebSocket("ws://" + server + "/ws_channel");
	
	this._socket.onopen = function() {
		console.log("Connection established");
	};
	
	this._socket.onmessage = function(msg) {
		var encoded = new Musubi.EncodedMessage(Crypto.util.base64ToBytes(msg.data));
		var decoded = Musubi.messageFormat.decode(encoded, thisTransport._keyPair);
		
		for (var key in thisTransport._listeners) {
			var l = thisTransport._listeners[key];
			l(decoded);
		}
	};
	
	this._socket.onclose = function() {
		console.log("Connection Closed");
	};
	
	this.onMessage = function(listener) {
		this._listeners.push(listener)
	}
};

Musubi.AMQPTransport.prototype.postObj = function(obj, feedName, sender, appId) {
	console.log(obj)
};

Musubi.EncodedMessage = function(data) {
	var sigLen = data[0] * 256 + data[1];
	
	this.signature = data.slice(2, 2 + sigLen);
	this.message = data.slice(2 + sigLen);
};