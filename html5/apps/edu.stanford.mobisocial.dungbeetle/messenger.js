/*
 * Status update
 */

function StatusUpdate(data) {
    this.text = data.text;
};

StatusUpdate.prototype.render = function() {
    return '<span>' + this.text + '</span>';
};

/*
 * JoinNotification update
 */

function JoinNotificationUpdate(data) {
}

JoinNotificationUpdate.prototype.render = function() {
    return '<span>I\'m here</span>';        
}

/*
 * Picture update
 */

function PictureUpdate(data) {
    this.data = data.data;
}

PictureUpdate.prototype.render = function() {
    return '<img src="data:image/jpeg;base64,' + this.data + '"/>';
}


/*
 * AppState update
 */

function AppStateUpdate(data) {
    this.html = data.html;
}

AppStateUpdate.prototype.render = function() {
    return this.html;
}

/*
 * UpdateFactory takes an Obj and creates the appropriate app-level Update object
 */
UpdateFactory = {}

UpdateFactory.createUpdateForObj = function(obj) {
    if (obj.type == "status")
        return new StatusUpdate(obj.data);
    else if (obj.type == "join_notification")
        return new JoinNotificationUpdate(obj.data);
    else if (obj.type == "picture")
        return new PictureUpdate(obj.data);
    else if (obj.type == "appstate")
        return new AppStateUpdate(obj.data);
    
};

/*
 * Messenger is the application's main class
 */

function Messenger(feed) {
    this.feed = feed;
    this.init();
}

// App initializations
Messenger.prototype.init = function() {
    var thisMessenger = this;
    
    if (this.feed) {
        // display feed title
        $('h1').html(this.feed.name);
        
        // render new messages on the feed
        this.feed.onNewMessage(this.renderMessage);
        
        // render existing messages on the feed
        this.feed.query(function(result) {
            result.forEach(thisMessenger.renderMessage);
        });
    }
};

// Posts a status to the feed
Messenger.prototype.postStatus = function(form) {
    var obj = new SocialKit.Obj({type: "status", data: {text: form.status.value}});
    this.feed.post(obj);
    
    form.status.value = "";
};    

// Renders messages on the feed
Messenger.prototype.renderMessage = function(msg) {
	var update = UpdateFactory.createUpdateForObj(msg);
    
    if (update) {
	    var elem = $('<li class="message"></li>');
	    elem.append('<div class="sender">' + msg.sender.name + '</div>');
	    elem.append('<div class="contents">' + update.render() + '</div>');
	    elem.append('<div class="date">' + msg.date + '</div>');
	    $('#messages').prepend(elem);
    }
};  

/*
 * App launch when Musubi is ready
 */
var messenger = null;
Musubi.ready(function(context) {
    messenger = new Messenger(context.feed);
});