/*
 * iOS platform interface
 */
console.log("hallo");
Musubi.platform = {
	_queryFeed: function(feedSession, query, sortOrder) {
    	Musubi.platform._runCommand("Feed", "messages", {feedName: feedName}, function(json) {
            // convert json messages to Objs
            var msgs = [];
            for (var key in json) {
                var msg = new SocialKit.Obj(json[key]);
                msgs.push(msg);
            }
            
            callback(msgs);
        });
    },
    
    _postObjToFeed: function(obj, feedSession) {
    	Musubi.platform._runCommand("Feed", "post", {feedSession: feedSession, obj: JSON.stringify(obj)});
    },
    
    _setConfig: function(config) {
        var cmdUrl = "config://?";
        for (var key in config) {
            cmdUrl += encodeURIComponent(key) + "=" + encodeURIComponent(config[key]) + "&";
        }
        
        window.location = cmdUrl;
    },
    
    
    _urlForRaw: function(objId) {
    	self._log("urlForRaw() not implemented yet");
    },
    
    _back: function() {
    	self._log("back() not implemented yet");
    },
     
    _quit: function() {
    	self._log("quit() not implemented yet");
    },
    
    _log: function(msg) {
        window.location = "console://?log=" + encodeURIComponent(msg);
    },
    
    _commandCallbacks: [],
    
    _runCommand: function(className, methodName, parameters, callback) {
        if (typeof callback == "undefined")
            callback = function() {};
        
        Musubi.platform._commandCallbacks.push(callback);
        
        var cmdUrl = "musubi://" + className + "." + methodName + "?";
        for (var key in parameters) {
            cmdUrl += encodeURIComponent(key) + "=" + encodeURIComponent(parameters[key]) + "&";
        }
        
        window.location = cmdUrl;
    },
    
    _commandResult: function(result) {
        var cb = Musubi.platform._commandCallbacks[0];
        delete Musubi.platform._commandCallbacks[0];
        if (cb != null) {
            cb(result);
        }
    }
};