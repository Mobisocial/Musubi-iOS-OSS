addEventListener('touchmove', function(e) { e.preventDefault(); }, true);

/*
 * WordPlay is the application's main class
 */
function WordPlay(app) {
    this.field = null;
    this.state = {bag: null, board: null, racks: null, players: null, scores: null, first: 0, gameover: 0, initializing: 0, lastmove: "", passcount: 0};
    this.init(app);
}
WordPlay.prototype = new SocialKit.Multiplayer.TurnBasedMultiplayerGame;

WordPlay.SPACE_REGULAR = 0;
WordPlay.SPACE_START = 1;
WordPlay.SPACE_DL = 2;
WordPlay.SPACE_TL = 3;
WordPlay.SPACE_DW = 4;
WordPlay.SPACE_TW = 5;
WordPlay.SPACETYPES = ["","","dl","tl","dw","tw"];

WordPlay.TILE_VALUES = {a: 1, b: 3, c: 3, d: 2, e: 1, f: 4, g: 2, h: 4, i: 1, j: 8, k: 5, l: 1, m: 3, n: 1, o: 1, p: 3, q: 10, r: 1, s: 1, t: 1, u: 1, v: 4, w: 4, x: 8, y: 4, z: 10, " ": 0};


// App initializations
WordPlay.prototype.init = function(app) {    
    
    this.field = this.createField();
    
    this.state.board = [];
    for (var i=0; i<15; i++) {
        this.state.board[i] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    }
    
    this.onUpdate(function(state) {
        this.state = state;
        $("#board").html(this.renderBoard());
        $("#rack").html(this.renderRack());
        $("#turn").html(this.isMyTurn() ? "It's your turn!" : "Waiting for other player.");
    });
    
    SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.init.call(this, app);
};

WordPlay.prototype.createField = function() {
    var __ = WordPlay.SPACE_REGULAR;
    var ST = WordPlay.SPACE_START;
    var DL = WordPlay.SPACE_DL;
    var TL = WordPlay.SPACE_TL;
    var DW = WordPlay.SPACE_DW;
    var TW = WordPlay.SPACE_TW;
    
    var field = [];
    field.push([TL,__,__,__,TW,__,__,DL,__,__,TW,__,__,__,TL]);
    field.push([__,DL,__,__,__,TL,__,__,__,TL,__,__,__,DL,__]);
    field.push([__,__,DW,__,__,__,DL,__,DL,__,__,__,DW,__,__]);
    field.push([__,__,__,TL,__,__,__,DW,__,__,__,TL,__,__,__]);
    field.push([TW,__,__,__,DW,__,DL,__,DL,__,DW,__,__,__,TW]);
    field.push([__,TL,__,__,__,TL,__,__,__,TL,__,__,__,TL,__]);
    field.push([__,__,DL,__,DL,__,__,__,__,__,DL,__,DL,__,__]);
    field.push([DL,__,__,DW,__,__,__,ST,__,__,__,DW,__,__,DL]);
    field.push([__,__,DL,__,DL,__,__,__,__,__,DL,__,DL,__,__]);
    field.push([__,TL,__,__,__,TL,__,__,__,TL,__,__,__,TL,__]);
    field.push([TW,__,__,__,DW,__,DL,__,DL,__,DW,__,__,__,TW]);
    field.push([__,__,__,TL,__,__,__,DW,__,__,__,TL,__,__,__]);
    field.push([__,__,DW,__,__,__,DL,__,DL,__,__,__,DW,__,__]);
    field.push([__,DL,__,__,__,TL,__,__,__,TL,__,__,__,DL,__]);
    field.push([TL,__,__,__,TW,__,__,DL,__,__,TW,__,__,__,TL]);
    return field;
}

// Returns a HTML rendering of the board 
WordPlay.prototype.renderBoard = function() {
    // need this because "this" will be out of scope in the makeCell function
    var thisGame = this;

    var table = $('<table cellpadding="0" cellspacing="0"></table>');
    for (var i=0; i<this.state.board.length; i++) {
        var row = $('<tr></tr>');
        for (var i2=0; i2<this.state.board[i].length; i2++) {
            // wrapped inside a function to locally scope idx
            var makeCell = function(rowIdx,colIdx) {
                var spaceType = WordPlay.SPACETYPES[thisGame.field[rowIdx][colIdx]];
                
                var cell = $('<td></td>');
                if (spaceType != "") {
                    cell.addClass('space_' + spaceType) 
                    cell.append(spaceType.toUpperCase())
                }
                var tile = thisGame.state.board[colIdx][rowIdx];
                if (tile != 0) {
                    cell.append('<div class="tile">' + tile.toUpperCase() + '<span class="value">' + WordPlay.TILE_VALUES[tile] + '</span></div>');

                }

                
/*                cell.click(function() {
                    thisGame.placeToken(idx);
                });*/
                return cell;
            };
            row.append(makeCell(i,i2));
        }
        table.append(row);
    }
    
    return table;
};

WordPlay.prototype.myPlayerIndex = function() {
    for (var idx = 0; idx < this.players.length; idx++) {
        if (this.players[idx].id == Musubi.user.id) {
            return idx;
        }
    }
    
    return -1;
};

WordPlay.prototype.cellForPoint = function(x, y) {
    
    var table = $("#board table");
    var xOffset = x - table[0].clientLeft;
    var yOffset = y - table[0].clientTop;
    
    var row = parseInt(Math.floor(yOffset / 19));
    var col = parseInt(Math.floor(xOffset / 19));
    
    console.log(row + "," + col);
    return table.find('tr').eq(row).find('td').eq(col);
};

// Returns a HTML rendering of my rack
WordPlay.prototype.renderRack = function() {
    // need this because "this" will be out of scope in the makeCell function
    var thisGame = this;
    var myRack = this.state.racks[this.myPlayerIndex()];
    
    var rack = $('<div></div>');
    for (var i=0; i<myRack.length; i++) {
        
        function createTile(idx) {
            var spot = $('<div class="spot"></div>');
            var tile = $('<div class="tile" draggable="true">' + myRack[idx].toUpperCase() + '<span class="value">' + WordPlay.TILE_VALUES[myRack[idx]] + '</span></div>');
            spot.append(tile);
            
            var lastPosition = [];
            tile.bind('dragstart', function (event) {
                $('body').append(tile);
            });
            tile.bind('drag', function (event) {
                tile.css("top", event.pageY - 15);
                tile.css("left", event.pageX - 15);
                lastPosition = {x: event.pageX - 15, y: event.pageY - 15};
            });
            tile.bind('dragend', function (event, options) {
                      elem = thisGame.cellForPoint(lastPosition.x, lastPosition.y);
                      tile.css("top", 0);
                      tile.css("left", 0);
                      elem.append(tile);
                //spot.append(tile);
            });
            
            return spot;
        }
        
        rack.append(createTile(i));
    }
    
    return rack;
};

WordPlay.prototype.feedView = function() {
    return '<html><head><style></style></head><body>WordPlay scores</body></html>';
}


/*
 * App launch when Musubi is ready
 */
var game = null;
Musubi.ready(function() {
    game = new WordPlay(Musubi.app);
});