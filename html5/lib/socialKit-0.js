DBG = true;
console.origLog = console.log;
console.log = function(msg) {
    console.origLog(msg);
    
    if (typeof msg == "object")
        msg = JSON.stringify(msg);
    
    if (typeof Musubi.platform == "object")
        Musubi.platform._log(msg);
};

SocialKit = {
};

Musubi = {
    _contexts: [],
    _launchCallback: null,
    _launch: function(user, feed, appId, message) {
        if (DBG) console.log("launching socialkit.js app");
    	Musubi.platform._setConfig({title: document.title});
        if (DBG) console.log("preparing musubi context");
    	var context = new SocialKit.AppContext({appId: appId, feed: feed, user: user, message: message});
        if (DBG) console.log("appending context");
    	Musubi._contexts.push(context);

    	if (Musubi._launchCallback != null) {
            if (DBG) console.log("launching app callback");
            Musubi._launchCallback(context);
            if (DBG) console.log("callback returned.");
        } else {
            if (DBG) console.log("no callback to launch.");
        }
    },
    
    _newMessage: function(msg) {
    	// Pass on to Feed instance
    	for (var key in Musubi._contexts) {
    		var context = Musubi._contexts[key];
    		if (context.feed.session == msg.feedSession) {
    			context.feed._newMessage(msg);
    		}
    	}
    },
    
    ready: function(callback) {
    	Musubi._launchCallback = callback
    },
};

Musubi.platform = {
	_messagesForFeed: function(feedSession, callback) {},
	_postObjToFeed: function(obj, feedSession) {},
	_setConfig: function(config) {},
	_log: function(msg) {},
        _quit: function() {}
}

/*
 * Platform initialization
 */
if (typeof Musubi_android_platform == "object") {
  if (DBG) console.log("android detected");
  Musubi.platform = {
    _messagesForFeed: function(feedSession, callback) {
      Musubi_android_platform._messagesForFeed(feedSession, callback);
    },
    _postObjToFeed: function(obj, feedSession) {
      Musubi_android_platform._postObjToFeed(JSON.stringify(obj), feedSession);
    },
    _setConfig: function(config) {
      Musubi_android_platform._setConfig(JSON.stringify(config));
    },
    _log: function(msg) {
      Musubi_android_platform._log(msg);
    },
    _quit: function() {
      Musubi_android_platform._quit();
    }
  };

  if (DBG) console.log("Android socialkit bridge loaded.");
}


/*
 * AppContext class
 */

SocialKit.AppContext = function(json) {
    if (DBG) console.log(">>> new AppContext(" + JSON.stringify(json));
    this.appId = json.appId;
    this.feed = new SocialKit.Feed(json.feed);
    this.message = json.message ? new SocialKit.SignedMessage(json.message) : null;
    this.user = json.user;
    this.quit = function() { Musubi.platform._quit(); }
    if (DBG) console.log("AppContext prepared.");
};

SocialKit.AppContext.prototype.toString = function() {
    return "<AppContext: " + this.appId + "," + this.feed.toString() + "," + this.message.toString() + ">";
};

/*
 * User class
 */

SocialKit.User = function(json) {
    if (DBG) console.log("User(" + JSON.stringify(json));
    this.name = json.name;
    this.id = json.id;
    this.personId = json.personId;
};

SocialKit.User.prototype.toString = function() {
    return "<User: " + this.id + "," + this.name + ">";
};

/*
 * Feed class
 */

SocialKit.Feed = function(json) {
    if (DBG) console.log("Feed(" + JSON.stringify(json));
    this.name = json.name;
    //this.uri = json.uri;
    this.session = json.session;
    //this.key = json.key;
    this.members = [];

    for (var key in json.members) {
        this.members.push( new SocialKit.User(json.members[key]) );
    }
    
    this._messageListener = null;
};

SocialKit.Feed.prototype.toString = function() {
    return "<Feed: " + this.name + "," + this.session + ">";
};

// Message listener
SocialKit.Feed.prototype.onNewMessage = function(callback) {
    this._messageListener = callback;
};

SocialKit.Feed.prototype._newMessage = function(json) {
    if (this._messageListener != null) {
        var msg = new SocialKit.SignedMessage(json);
        this._messageListener(msg);
    }
};
    
// Message querying
SocialKit.Feed.prototype.messages = function(callback) {
	Musubi.platform._messagesForFeed(this.session, callback);
};

// Message posting
SocialKit.Feed.prototype.post = function(obj) {
	Musubi.platform._postObjToFeed(obj, this.session);
};


/*
 * Obj class
 */

SocialKit.Obj = function(json) {
    this.type = json.type;
    this.data = json.data;
};

SocialKit.Obj.prototype.toString = function() {
    return "<Obj: " + this.type + "," + JSON.stringify(this.data) + ">";
};

/*
 * Message class
 */

SocialKit.Message = function(json) {
    this.obj = null;
    this.sender = null;
    //this.recipients = [];
    this.appId = null;
    this.feedSession = null;
    this.date = null;
    
    if (json)
        this.init(json);
};

SocialKit.Message.prototype.init = function(json) {
    if (DBG) console.log("Message(" + JSON.stringify(json));
    this.obj = new SocialKit.Obj(json.obj);
    this.sender = new SocialKit.User(json.sender);
    /*this.recipients = [];
    
    for (var key in json.recipients) {
        this.members.push( new SocialKit.User(json.recipients[key]) );
    }*/
    
    this.appId = json.appId;
    this.feedSession = json.feedSession;
    this.date = new Date(parseInt(json.timestamp));
};

SocialKit.Message.prototype.toString = function() {
    return "<Message: " + this.obj.toString() + "," + this.sender.toString() + "," + this.appId + "," + this.feedSession + "," + this.date + ">";
};

/*
 * SignedMessage class
 */

SocialKit.SignedMessage = function(json) {
    if (DBG) console.log("SignedMessage(" + JSON.stringify(json));
    this.hash = null;
    if (json)
        this.init(json);
};
SocialKit.SignedMessage.prototype = new SocialKit.Message;

SocialKit.SignedMessage.prototype.init = function(json) {
    SocialKit.Message.prototype.init.call(this, json);
    this.hash = json.hash;
};

//document.dispatchEvent(document.createEvent('socialKitReady'));
//$.event.trigger({type: 'socialKitReady'});
