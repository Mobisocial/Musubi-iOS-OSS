/*
 * Browser platform interface
 */

Musubi.Browser = {};

Musubi.Browser.Environment = function(transport) {
	var thisEnv = this;
	this._instances = {};
	this._transport = transport;
	
	this._transport.onMessage(function(msg) {
		for (var frame in thisEnv._instances) {
			var context = thisEnv._instances[frame].context;
			if (msg.type == "appstate" && msg.appId != context.appId ) {
				thisEnv.startInstance(frame, context.user, context.feed, msg.appId, msg);
			} else {
				var instance = thisEnv._instances[frame].instance;
				instance._newMessage(msg);
			}
		}
	});
	
	this._loadAppInFrame = function(appId, frame, callback) {
		var frm = window.frames[frame];
		
		frm.location = '../apps/' + appId + '/index.html';
		$('[name=' + frame + ']').load(function() {
			$('[name=' + frame + ']').unbind('load');
			callback(frm.Musubi);
		});
	};
	
	this.startInstance = function(frame, user, feed, appId, msg) {
		var context = {appId: appId, feed: feed, user: user, message: msg};
		
		var prevInstance = this._instances[frame];
		if (prevInstance)
			delete prevInstance.instance.platform;
		
		thisEnv._loadAppInFrame(appId, frame, function(instance) {
			thisEnv._instances[frame] = {instance: instance, context: context};
			instance.platform = Musubi.Browser.IFramePlatformFactory(thisEnv._transport, context);	
			instance._launch(user, feed, appId, null);
		});
	};
}

Musubi.Browser.IFramePlatformFactory = function(transport, context) {
	return {
		_queryFeed: function(feedId, query, sortOrder) {
			return null;
		},
		_postObjToFeed: function(obj, feedSession) {
			transport.postObj(obj, context.feed.session, context.user, context.appId);
	    },
	
		// these are not important in our context
	    _setConfig: function(config) {},
	    _log: function(msg) {}
	}
};

Musubi.Browser.InterFrameTransport = function(feedName) {
	this._messageListener;
	
	this.postObj = function(obj, feedSession, sender, appId) {
		console.log(obj);
		
		var msg = new SocialKit.Obj();
		msg.timestamp = new Date().getTime();
    	msg.feedSession = feedSession;
    	msg.appId = appId;
    	msg.sender = sender;
    	msg.type = obj.type;
    	msg.data = obj.data;
    	
    	this._messageListener(msg);
	};
	
	this.onMessage = function(callback) {
		this._messageListener = callback;
	}
};