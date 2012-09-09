/*
 * TicTacToe is the application's main class
 */
function TicTacToe(app) {
    this.board = ["  ","  ","  ","  ","  ","  ","  ","  ","  "];
    this.init(app);
    this.myToken = this.players[0].id == this.appContext.user.id ? "X" : "O";
}
TicTacToe.prototype = new SocialKit.Multiplayer.TurnBasedMultiplayerGame;

// App initializations
TicTacToe.prototype.init = function(app) {    
    //this.renderBoard();
    this.onUpdate(function(state) {
        this.board = state.s;
        $("#board").html(this.renderBoard());
        $("#turn").html(this.isMyTurn() ? "It's your turn!" : "Waiting for other player.");
    });

    SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.init.call(this, app);
    for (var key in this.players) {
        $("#players").append('<li>' + this.players[key].name + '</li>');
    }
};

TicTacToe.prototype.createInitialState = function() {
	this.state = {s: ["  ","  ","  ","  ","  ","  ","  ","  ","  "]};
	return this.state;
}

// Returns a HTML rendering of the board 
TicTacToe.prototype.renderBoard = function() {
    // need this because "this" will be out of scope in the makeCell function
    var thisGame = this;

    var table = $('<table cellpadding="0" cellspacing="0"></table>');
    for (var i=0; i<3; i++) {
        var row = $('<tr></tr>');
        for (var i2=0; i2<3; i2++) {
            // wrapped inside a function to locally scope idx
            var makeCell = function(idx) {
                var cell = $('<td>&nbsp;' + thisGame.board[idx] + '</td>');
                cell.click(function() {
                    if (DBG) console.log("TTT clicked " + idx);
                    thisGame.placeToken(idx);
                });
                row.append(cell);
            };
            makeCell(i*3+i2);
        }
        table.append(row);
    }
    
    return table;
};

TicTacToe.prototype.placeToken = function(idx) {
    if (DBG) console.log("placing token.. " + JSON.stringify(this));
    if (!this.isMyTurn()) {
        if (DBG) console.log("not my turn.");
        return;
    }
    // only place token on empty spots
    if (this.board[idx] == "  ") {
        this.board[idx] = this.myToken;
        this.takeTurn(this.makeState())
    }
};

// Returns the state
TicTacToe.prototype.makeState = function() {
    if (DBG) console.log("making state...");
    return {s: this.board};
};

TicTacToe.prototype.reset = function() {
    if (this.isMyTurn()) {
        this.board = ["  ","  ","  ","  ","  ","  ","  ","  ","  "];
        this.takeTurn(this.makeState())
    }
};

TicTacToe.prototype.feedView = function() {
    var container = $('<div></div>');
    container.append(this.renderBoard());
    var cssRules = document.styleSheets[0].cssRules;
    var css = "";
    for (var i=0; i<cssRules.length; i++) {// cssRules.length; i++) {
        if (cssRules[i].cssText)
            css += cssRules[i].cssText + " ";
        
    }
    return '<html><head><style>' + css + '</style></head><body><div id="board">' + container.html() + '</div></body></html>';
}


/*
 * App launch when Musubi is ready
 */
var game = null;
Musubi.ready(function(context) {
    console.info("launching tictactoe");
    game = new TicTacToe(context);
});
