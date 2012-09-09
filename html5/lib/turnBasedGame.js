if (typeof SocialKit == "undefined") SocialKit = {}
if (typeof SocialKit.Multiplayer == "undefined") SocialKit.Multiplayer = {}


/*
 * MultiplayerGame is a base class for different types of multiplayer games
 */

SocialKit.Multiplayer.MultiplayerGame = function() {
    this.appContext = null;
    this.players = [];
    this._updateListener = null;
    
    this.OBJ_MEMBERSHIP = "membership";
}

// Initializes the game. A game is started on a feed with an Obj
SocialKit.Multiplayer.MultiplayerGame.prototype.init = function(context) {
    if (DBG) console.log("MultiplayerGame(" + JSON.stringify(context));
    this.appContext = context;
    
    // Get the members from the Obj the app was launched with
    var localUser = context.user;
    var gameMembers = this.appContext.message ? this.appContext.message.obj.data[this.OBJ_MEMBERSHIP] : null;
    if (gameMembers) {
        this.players = [];
        for (var key in gameMembers) {
            var gameMember = gameMembers[key];
            if (gameMember == localUser.personId) {
                this.players.push(new SocialKit.User(localUser));
            } else {
                for (var key in this.appContext.feed.members) {
                    var feedMember = this.appContext.feed.members[key];
                    if (gameMember == feedMember.personId) {
                        this.players.push(feedMember);
                        break;
                    }
                }
            }
        }

        if (this.players.length < 2) {
            alert("MultiplayerGame was launched with < 2 players");
            return;
        }
    } else {
        console.log("*** SocialKit.js falling back to dummy users");
        this.players = [new SocialKit.User({name: "User 1", id: 0}), new SocialKit.User({name: "User 2", id: 1})]
    }

    if (DBG) console.log("initializing game: " + this._currentPlayerIdx);
    this.state = this.createInitialState();

    var objData = {}
    objData[this.OBJ_PLAYERINCONTROL] = this._currentPlayerIdx;
    objData[this.OBJ_TURN] = this._lastTurn;
    objData[this.OBJ_MEMBERSHIP] = this._playerIds();
    objData.html = this.feedView();
    objData.state = this.state;

    this.appContext.feed.post(new SocialKit.Obj({type: "appstate", data: objData}));
    this._updateListener(this.state);
}

SocialKit.Multiplayer.MultiplayerGame.prototype._playerIds = function() {
    var ids = []
    for (var key in this.players) {
        ids.push(this.players[key].personId);
    }
    return ids;
}

SocialKit.Multiplayer.MultiplayerGame.prototype.onUpdate = function(callback) {
    this._updateListener = callback;
};

SocialKit.Multiplayer.MultiplayerGame.prototype.feedView = function() {
    return "<span>Please override MultiplayerGame.prototype.feedView()</span>";
};

/*
 * TurnBasedMultiplayerGame extends MultiplayerGame
 */

SocialKit.Multiplayer.TurnBasedMultiplayerGame = function() {
    this._currentPlayerIdx = 0;
    this._lastTurn = 0;
    this.state = null;
    
    this.OBJ_PLAYERINCONTROL = "member_cursor";
    this.OBJ_TURN = "key_int";
};
SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype = new SocialKit.Multiplayer.MultiplayerGame;

// Initializes the game
SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.init = function(appContext) {
    // call super.init()
    SocialKit.Multiplayer.MultiplayerGame.prototype.init.call(this, appContext);

    // listen for messages on the feed
    var thisGame = this;
    var msgListener = function(msg) {
        thisGame._processMove(msg.data);
    }
    appContext.feed.onNewMessage(msgListener);
    
    // process the obj the app was launched with
    if (appContext.message) {
        if (DBG) console.log("Prepping with " + JSON.stringify(appContext.message));
        var obj = appContext.message.obj.data;
        if (typeof(obj[this.OBJ_PLAYERINCONTROL]) == 'undefined') {
            obj[this.OBJ_PLAYERINCONTROL] = 0;
        }
    	this._processMove(obj);
    }
};

SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.createInitialState = function() {
	return null;
};

// Checks whether I am in control of the state machine at this point
SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.isMyTurn = function() {
    if (DBG) console.log("checking turn " + this.players + ", " + this._currentPlayerIdx);
    return (this.players[this._currentPlayerIdx].id == this.appContext.user.id);
};
SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.takeTurn = function(state, nextPlayer) {
    if (DBG) console.log("takingTurn()");
    if (!this.isMyTurn()) {
        return false;
    }
    if (DBG) console.log("it's my turn");
    this.state = state;
    this._lastTurn++;

    if (nextPlayer) {
        this._currentPlayerIdx = this.players.indexOf(nextPlayer);        
    } else {
        this._currentPlayerIdx = (this._currentPlayerIdx+1) % this.players.length;
    }

    var objData = {}
    objData[this.OBJ_PLAYERINCONTROL] = this._currentPlayerIdx;
    objData[this.OBJ_TURN] = this._lastTurn;
    objData[this.OBJ_MEMBERSHIP] = this._playerIds();
    objData.html = this.feedView();
    objData.state = this.state;

    if (DBG) console.log("posting " + JSON.stringify(objData));
    this.appContext.feed.post(new SocialKit.Obj({type: "appstate", data: objData}));
    this._updateListener(this.state);
};

SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype._processMove = function(objData) {
    /*
    var turn = objData[SocialKit.Multiplayer.TurnBasedMultiplayerGame.OBJ_TURN];
    alert("Got move " + turn);
    
    if (!turn) {
        alert("Obj without turn!");
    } else if (move < this._lastTurn) {
        alert("Already know about a later turn!");
    } else {
        this._lastTurn = turn;
    }
    */
    
    this._currentPlayerIdx = objData[this.OBJ_PLAYERINCONTROL];
    if (objData.state) {
        this.state = objData.state;
        this._updateListener(this.state);
    }
}
