addEventListener('touchmove', function(e) { e.preventDefault(); }, true);

/*
 * WordPlay is the application's main class
 */
function WordPlay(context) {
    this.field = null;
    this.state = {bag: null, board: null, racks: null, players: null, scores: null, first: 0, gameover: 0, initializing: 0, lastmove: "", passcount: 0};
    this.init(context);
}
WordPlay.prototype = new SocialKit.Multiplayer.TurnBasedMultiplayerGame;

WordPlay.SPACE_REGULAR = 0;
WordPlay.SPACE_START = 1;
WordPlay.SPACE_DL = 2;
WordPlay.SPACE_TL = 3;
WordPlay.SPACE_DW = 4;
WordPlay.SPACE_TW = 5;
WordPlay.SPACETYPES = ["","st","dl","tl","dw","tw"];

WordPlay.TILE_VALUES = {a: 1, b: 3, c: 3, d: 2, e: 1, f: 4, g: 2, h: 4, i: 1, j: 8, k: 5, l: 1, m: 3, n: 1, o: 1, p: 3, q: 10, r: 1, s: 1, t: 1, u: 1, v: 4, w: 4, x: 8, y: 4, z: 10, " ": 0};


// App initializations
WordPlay.prototype.init = function(context) {    
    
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
    
    SocialKit.Multiplayer.TurnBasedMultiplayerGame.prototype.init.call(this, context);
};

WordPlay.prototype.createInitialState = function() {
	state = {bag: null, board: null, racks: null, players: null, scores: null, first: 0, gameover: 0, initializing: 1, lastmove: "", passcount: 0};
	
	state.bag = ['a','a','a','a','a','a','a','a','a',
					'b','b',
					'c','c',
					'd','d','d','d',
					'e','e','e','e','e','e','e','e','e','e','e','e',
					'f','f',
					'g','g','g',
					'h','h',
					'i','i','i','i','i','i','i','i','i',
					'j',
					'k',
					'l','l','l','l',
					'm','m',
					'n','n','n','n','n','n',
					'o','o','o','o','o','o','o','o',
					'p','p',
					'q',
					'r','r','r','r','r','r',
					's','s','s','s',
					't','t','t','t','t','t',
					'u','u','u','u',
					'v','v',
					'w','w',
					'x',
					'y','y',
					'z',
					' ',' '];
	
	state.board = [];
	for (var i=0; i<15; i++) {
        state.board[i] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    }
    
    state.racks = [];
    state.scores = [];
    
    for (var i in this.players) {
    	state.scores.push(0);
    	state.racks[i] = [];
    	
    	for (var p = 0; p < 7; p++) {
    		state.racks[i][p] = this.takeTileFromBag(state.bag);
    	}
    }
    
    return state;
};

WordPlay.prototype.takeTileFromBag = function(bag) {
	var i = -1;
	while (i < 0 || !bag[i]) {
		i = Math.round(Math.random() * bag.length);
	}
	
	tile = bag.splice(i,1)
	return tile[0];
}

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
        if (this.players[idx].id == this.appContext.user.id) {
            return idx;
        }
    }
    
    return -1;
};

WordPlay.prototype.placement = function() {
	var placement = {}
	$("div.tile").each(function() {
		var pos = $(this).data("position");
		if (pos) {
			var x = pos % 15;
			var y = Math.floor(pos / 15);
			
			if (!placement[y])
				placement[y] = {};
			
			placement[y][x] = {letter: $(this).data("letter")};
		}
	});
	return placement;
};

WordPlay.prototype.placementProperties = function(placement) {
	var properties = {start: null, end: null, dimension: null};
	var commonX;
	var commonY;
	
	for (var y in placement) {
		if (!commonY || y == commonY)
			commonY = y;
		else
			commonY = -1;
		
		for (var x in placement[y]) {
			if (!properties.start) {
				properties.start = {x: x, y: y};
			}
			
			properties.end = {x: x, y: y};
			
			if (!commonX || x == commonX)
				commonX = x;
			else
				commonX = -1;
		}
	}
	
	if (commonX >= 0)
		properties.dimension = "y";
	else if (commonY >= 0)
		properties.dimension = "x";
	
	return properties;
};

WordPlay.prototype.findWordInPlacementAtPosition = function(position, dimension, placement) {
	var thisGame = this;
	
	var letterAtPosition = function(pos) {
		var letter = thisGame.state.board[pos.y][pos.x];
		if (!letter && placement[pos.y] && placement[pos.y][pos.x]) {
			letter = placement[pos.y][pos.x].letter;
		}
		if (letter) {
			var slot_type = thisGame.field[pos.y][pos.x];
			var letter_multiplier = slot_type == WordPlay.SPACE_TL ? 3 : (slot_type == WordPlay.SPACE_DL ? 2 : 1)
			var word_multiplier = slot_type == WordPlay.SPACE_TW ? 3 : (slot_type == WordPlay.SPACE_DW ? 2 : 1)
			return {letter: letter, value: WordPlay.TILE_VALUES[letter] * letter_multiplier, word_multiplier : word_multiplier};
		} else {
			return null;
		}
	}
	
	var word = [];
	
	var testPos = {x:position.x, y:position.y};
	while (testPos[dimension] >= 0) {
		var letter = letterAtPosition(testPos);
		if (letter) {
			word.unshift(letter);
		} else {
			break;
		}
		testPos[dimension]--;
	}
	
	var testPos = {x:position.x, y:position.y};
	while (testPos[dimension] < 14) {
		testPos[dimension]++;
		var letter = letterAtPosition(testPos);
		if (letter) {
			word.push(letter);
		} else {
			break;
		}
	}
	
	if (word.length > 1)
		return word;
	else
		return null;
};

WordPlay.prototype.placementWords = function() {
	var placement = this.placement();
	var properties = this.placementProperties(placement);
	
	if (!properties.dimension)
		return null;
	
	var words = [];
	var word = this.findWordInPlacementAtPosition(properties.start, properties.dimension, placement);
	words.push(word);
		
	if (!word || (properties.end[properties.dimension] - properties.start[properties.dimension]) != (word.length - 1)) {
		return null;
	}
	
	pointer = [properties.start.x, properties.start.y];
	for (var y in placement) {
		for (var x in placement[y]) {
			word = this.findWordInPlacementAtPosition({x:x, y:y}, -(properties.dimension-1), placement);
			if (word) { words.push(word); }
		}
	}

	return words;
};

WordPlay.prototype.elemForPoint = function(x, y, parent, elemWidth, elemHeight, rowCount, colCount) {
    var xOffset = x - parent[0].offsetLeft;
    var yOffset = y - parent[0].offsetTop;
    
    console.log(xOffset + ", " + yOffset)
    
    var row = parseInt(Math.floor(yOffset / elemHeight));
    var col = parseInt(Math.floor(xOffset / elemWidth));
    
    if (row >= 0 && row < rowCount && col >= 0 && col < colCount)
    	return row * colCount + col;
    else
    	return -1;
};

WordPlay.prototype.cellForPoint = function(x, y) {
	return this.elemForPoint(x, y, $("#board table"), 19, 19, 15, 15);
};

WordPlay.prototype.spotForPoint = function(x, y) {
	return this.elemForPoint(x, y, $("#rack div"), 38, 38, 1, 7);
};

// Returns a HTML rendering of my rack
WordPlay.prototype.renderRack = function() {
    // need this because "this" will be out of scope in the makeCell function
    var thisGame = this;
    var myRack = this.state.racks[this.myPlayerIndex()];
    var zoomedTile = null;
    
    var rack = $('<div></div>');
    for (var i=0; i<myRack.length; i++) {
        
        function createTile(idx) {
            var spot = $('<div class="spot"></div>');
            var tile = $('<div class="tile" draggable="true">' + myRack[idx].toUpperCase() + '<span class="value">' + WordPlay.TILE_VALUES[myRack[idx]] + '</span></div>');
            tile.data("letter", myRack[idx]);
            spot.append(tile);
            
            var lastPosition = [];
            tile.bind('dragstart', function (event) {
                $('body').append(tile);
            });
            tile.bind('drag', function (event) {
                tile.css("top", event.pageY - 20);
                tile.css("left", event.pageX - 20);
                tile.css("width", "40px");
                tile.css("height", "40px");
                lastPosition = {x: event.pageX, y: event.pageY};
                
                var newSpot = thisGame.spotForPoint(lastPosition.x, lastPosition.y);
                if (newSpot != currentSpot) {
                	// move whatever is at current spot towards
                } 
            });
            tile.bind('dragend', function (event, options) {
            	tile.css("top", "");
            	tile.css("left", "");
            	tile.css("width", "");
            	tile.css("height", "");
            	
            	pos = thisGame.cellForPoint(lastPosition.x, lastPosition.y);
            	if (pos >= 0) {
            		elem = $("#board table").find('tr').eq(Math.floor(pos / 15)).find('td').eq(pos % 15);
	            	elem.append(tile);
	            	tile.data("position", pos);
            	} else {
            		newSpot = thisGame.spotForPoint(lastPosition.x, lastPosition.y);
            		if (newSpot >= 0) {
            			console.log("Moving to spot " + newSpot);
            			
            			
            		} else {
            			spot.append(tile);
            			tile.data("position", null);
            		}
	            	
            	}
            	
            	console.log(thisGame.placement());
            });
            
            return spot;
        }
        
        rack.append(createTile(i));
    }
    
    return rack;
};

WordPlay.prototype.shuffle = function() {
	var myRack = this.state.racks[this.myPlayerIndex()];
	if (myRack.length != $("#rack").find(".tile").length) {
		console.log("Tiles have been placed!");
	} else {
		// Fisher-Yates shuffle
		for(var j, x, i = myRack.length; i; j = parseInt(Math.random() * i), x = myRack[--i], myRack[i] = myRack[j], myRack[j] = x);
		this.state.racks[this.myPlayerIndex()] = myRack;
		$("#rack").html(this.renderRack());
	}
};

WordPlay.prototype.feedView = function() {
    return '<html><head><style></style></head><body>WordPlay scores</body></html>';
}


/*
 * App launch when Musubi is ready
 */
game = null;
Musubi.ready(function(context) {
    game = new WordPlay(context);
});