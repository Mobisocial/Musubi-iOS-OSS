DBG = true;
var globalAppContext
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
    _launch: function(user, feed, appId, obj) {
        if (DBG) console.log("launching socialkit.js app");
        	Musubi.platform._setConfig({title: document.title});
        if (DBG) console.log("preparing musubi context");
        	var context = new SocialKit.AppContext({appId: appId, feed: feed, user: user, obj: obj});
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
        		if (context.feed.session == msg.session) {
        			context.feed._newMessage(msg);
        		}
        	}
    },
    
    ready: function(callback) {
    	    Musubi._launchCallback = callback;
    },

    
    urlForRawData: function(objId) {
      return Musubi.platform._urlForRaw(objId);
    }
};

Musubi.platform = {
	_queryFeed: function(feedId, query, sortOrder) {},
	_postObjToFeed: function(obj, session) {},
        _urlForRaw: function(objId) {},
        _back: function(objId) {},
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
    _queryFeed: function(feedId, query, sortOrder) {
      return JSON.parse(Musubi_android_platform._queryFeed(feedId, query, sortOrder));
    },
    _postObjToFeed: function(obj, session) {
      Musubi_android_platform._postObjToFeed(JSON.stringify(obj), session);
    },
    _urlForRaw: function(objId) {
      return Musubi_android_platform._urlForRaw(objId);
    },
    _back: function() {
      Musubi_android_platform._back();
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

SocialKit.AppContext = function(data) {
    if (DBG) console.log(">>> new AppContext(" + JSON.stringify(data));
    this.appId = data.appId;
    this.feed = new SocialKit.Feed(data.feed);
    this.obj = data.obj ? new SocialKit.DbObj(data.obj) : null;
    this.user = data.user;
    this.forceQuit = false;
    this.overwriteBack = false;
    this.quit = function() { 
                    this.forceQuit = true; 
                    Musubi.platform._quit(); 
                };
    this.realBack = function() { this.quit(); };
    this.back = function() { Musubi.platform._quit(); };
                    /*this.realBack();
                    if(!this.forceQuit && !this.overwriteBack) { 
                        Musubi.platform._back(); 
                    } 
                };*/
    globalAppContext = this;
    if (DBG) console.log("AppContext prepared.");
};

SocialKit.AppContext.prototype.setBack = function(newSetBack) { 
    this.back = newSetBack;
    /*this.overwriteBack = true;
    this.realBack = function() { 
        newSetBack();
        if(!this.forceQuit) { 
            Musubi.platform._back(); 
        } 
    }; */
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
    this.uri = json.uri;
    this.session = json.session;
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
        var msg = false; // new SocialKit.SignedMessage(json);
        this._messageListener(msg);
    }
};
    
// Message querying
SocialKit.Feed.prototype.query = function(query, sortOrder) {
	return Musubi.platform._queryFeed(this.session, query, sortOrder);
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
    this.json = json.json;
    this.raw_data_url = json.raw_data_url;
    this.intKey = json.intKey;
    this.stringKey = json.stringKey;
};

SocialKit.Obj.prototype.toString = function() {
    return "<Obj: " + this.type + "," + JSON.stringify(this.json) + ">";
};

/*
 * Objects persisted in SocialDB
 */

SocialKit.DbObj = function(json) {
    this.sender = null;
    this.recipients = [];
    this.appId = null;
    this.session = null;
    this.date = null;

    if (json) {
        this.init(json);
    }
};

SocialKit.DbObj.prototype.init = function(json) {
    if (DBG) console.log("DbObj(" + JSON.stringify(json));
    this.sender = new SocialKit.User(json.sender);
    this.recipients = [];
    this.objId = json.objId;
    this.data = json.data;
    
    for (var key in json.recipients) {
        this.members.push( new SocialKit.User(json.recipients[key]) );
    }
    
    this.appId = json.appId;
    this.session = json.session;
    this.date = new Date(parseInt(json.timestamp));
};

SocialKit.DbObj.prototype.toString = function() {
    return "<DbObj: " + this.objId + "," + this.sender.toString() + "," + this.appId + "," + this.session + "," + ((this.data != null) ? JSON.stringify(this.data) : null) + ">";
};


//document.dispatchEvent(document.createEvent('socialKitReady'));
//$.event.trigger({type: 'socialKitReady'});
