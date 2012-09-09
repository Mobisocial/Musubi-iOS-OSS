if (typeof SocialKit == "undefined") SocialKit = {}
if (typeof SocialKit.Multiplayer == "undefined") SocialKit.Multiplayer = {}


/*
 * MultiplayerGame is a base class for different types of multiplayer games
 */

SocialKit.Multiplayer.MultiplayerGame = function() {
    this.app = null;
    this.players = [];
    this._updateListener = null;
    
    this.OBJ_MEMBERSHIP = "membership";
}

// Initializes the game. A game is started on a feed with an Obj
SocialKit.Multiplayer.MultiplayerGame.prototype.init = function(app) {
    this.app = app;
    
    // Get the members from the Obj the app was launched with
    var gameMembers = this.app.message.obj.data[this.OBJ_MEMBERSHIP];
    if (gameMembers) {
        this.players = [];
        
        for (var key in gameMembers) {
            var gameMember = gameMembers[key];
            
            for (var key in this.app.feed.members) {
                var feedMember = this.app.feed.members[key];
                
                if (gameMember == feedMember.personId) {
                    this.players.push(feedMember);
                }
            }
        }
        
        if (this.players.length < 2) {
            alert("MultiplayerGame was launched with < 2 players");
            return;
        }
    } else {
        alert("MultiplayerGame was launched without players");
        return;
    }
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
SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.init = function(app) {
    // call super.init()
    SocialKit.Multiplayer.MultiplayerGame.prototype.init.call(this, app);
    
    // listen for messages on the feed
    var thisGame = this;
    var msgListener = function(msg) {
        thisGame._processMove(msg.obj.data);
    }
    app.feed.onNewMessage(msgListener);
    
    // process the obj the app was launched with
    this._processMove(app.message.obj.data);
};

// Checks whether I am in control of the state machine at this point
SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.isMyTurn = function() {
    return (this.players[this._currentPlayerIdx].id == Musubi.user.id);
};

SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.takeTurn = function(state, nextPlayer) {
    if (!this.isMyTurn()) {
        return false;
    }
    
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

    this.app.feed.post(new SocialKit.Obj({type: "appstate", data: objData}));
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
