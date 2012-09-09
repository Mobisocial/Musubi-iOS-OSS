/**
 * Musu Sketch
 */
var testingInBrowser = false;

var sketch; // Global context for SketchApp.
var mx = 0; // TODO: someone with "javascript skills" should make this object oriented.
var my = 0;
var Mx = 0;
var My = 0;
var canvas = null;
var usingEraser = false;
var undoStack = new Array();

Musubi.ready(function(appContext) {
  canvas = document.getElementById("sketchpad");
  var args = {id:"sketchpad", size: parseInt($("#width").val()), color: $("#color").css("background-color") };
  if (appContext.obj != null) {
    var img = Musubi.urlForRawData(appContext.obj.objId);
    if (img != null) {
      args.bg = img;
    }
  }

  sketch = new SketchApp(args); 

  $("#post").click(function(e) {
    var elm = document.getElementById('sketchpad');
    var copy = document.createElement("canvas");
    var w = Mx - mx;
    var h = My - my;
    copy.width = w + 20;
    copy.height = h + 20;
    var cpx = copy.getContext("2d");
    cpx.fillStyle = "white";
    cpx.fillRect(0,0,copy.width, copy.height);
    cpx.drawImage(elm, mx, my, w, h, 10, 10, w, h);
    var snapshot = copy.toDataURL();

    var json = { "mimeType" : "image/jpeg" };
    var obj = new SocialKit.Obj({"type" : "picture", "raw_data_url": snapshot, "json": json });
    if (!testingInBrowser) {
      appContext.feed.post(obj);
      appContext.quit();
    }
  });
  
  $("#clear").click(function(e) {
	clearCanvas();
	undoStack.push({type: "clear"});
  });
  
  $("#undo").click(function(e) {
	undoStack.pop();
	clearCanvas();
	redrawFromUndoStack();
  });
	
  $("#tool").change(function(e) {
	var v = $(this).val();
	if (v == "Pen") {
		$("#color").show();
		usingEraser = false;
	} else if (v == "Eraser") {
		$("#color").hide();
		usingEraser = true;
	}
  });

  /**
   * Adjust touch event bindings if the screen rotates
   */
  var supportsOrientationChange = "onorientationchange" in window,
      orientationEvent = supportsOrientationChange ? "orientationchange" : "resize";

  window.addEventListener(orientationEvent, function() {
    // window.orientation, screen.width
    orientationUpdate();
  }, false);


  $("#color").click(function(e) {
    showColorPicker();
  });
});


function orientationUpdate() {

}

function onImageLoaded(img) {
  console.log("onImageLoaded(" + img);
  var canvas = document.getElementById("sketchpad"),
  ctxt = canvas.getContext("2d");

  var aspect = img.width / img.height;
  var scaleWidth = canvas.width;
  var scaleHeight = scaleWidth / aspect;
  if (scaleHeight > canvas.height) {
    console.log("rescaling from height " + scaleHeight);
    scaleHeight = canvas.height;
    scaleWidth = scaleHeight * aspect;
  }
  var sy = (canvas.height - scaleHeight) / 2;
  var sx = 0;

  mx = sx;
  my = sy;
  Mx = scaleWidth + mx; 
  My = scaleHeight + my;

  ctxt.drawImage(img, sx, sy, scaleWidth, scaleHeight);  
  console.log("drawing img " + scaleWidth + "x" + scaleHeight);
}

// CanvasDrawr originally from Mike Taylr  http://miketaylr.com/
// Tim Branyen massaged it: http://timbranyen.com/
// and i did too. with multi touch.
// and boris fixed some touch identifier stuff to be more specific.
           
var SketchApp = function(options) {
  // grab canvas element
  var drawing = false;
  var moved = false;
  var canvas = document.getElementById(options.id),
  ctxt = canvas.getContext("2d");

  canvas.style.width = '100%'
  canvas.width = canvas.offsetWidth;
  canvas.style.width = '';

  canvas.style.height = $("body").height();
  canvas.height = canvas.offsetHeight;
  //canvas.style.height = '';

  Mx = 0;
  My = 0;
  mx = canvas.width;
  my = canvas.height;

  // set props from options, but the defaults are for the cool kids
  ctxt.lineWidth = options.size || Math.ceil(Math.random() * 35);
  ctxt.lineCap = options.lineCap || "round";
  ctxt.pX = undefined;
  ctxt.pY = undefined;

  ctxt.fillStyle = "white";
  ctxt.fillRect(0,0,canvas.width, canvas.height);

  if (options.bg) {
    $("body").append("<img src='"+options.bg+"' onload='onImageLoaded(this)' style='display:none;' />");
  }

  var lines = [,,];
  var lineDrawData; // saves line drawing information in a single array 
  var offset = $(canvas).offset();
               
  var self = {
    //bind click events
    init: function() {
      //set pX and pY from first click
      canvas.addEventListener('touchstart', self.preDraw, false);
      canvas.addEventListener('touchmove', self.draw, false);
	  canvas.addEventListener('touchend', self.postDraw, false);

      return this;
    },
    postDraw: function(event) {
	  if (!moved) {
		// draw a point instead of a line
		var centerX = lines[0].x;
		var centerY = lines[0].y;
		var radius = parseInt($("#width").val()) / 2;
		var color = $("#color").css("background-color");
		drawPoint(ctxt, centerX, centerY, radius, color);
		
		// save to undo stack
		var toStack = { type: "point", data: {x: centerX, y: centerY, r: radius, color: color} };
		undoStack.push(toStack);
	  } else {
		// save line to undo stack
		var toStack = { type: "line", data: lineDrawData };
		undoStack.push(toStack);
	  }
	  moved = false;
      drawing = false;
    },
    preDraw: function(event) {
	  lineDrawData = new Array();
      offset = $(canvas).offset();
      if (event.type == "mousedown") {
        drawing = true;
        lines[0] = { x : this.pageX - offset.left,
                     y : this.pageY - offset.top,
                     color : $("#color").css("background-color"),
					 size: parseInt($("#width").val())
                   };
      } else {
        $.each(event.touches, function(i, touch) {
          var id = touch.identifier;
          lines[id] = { x : this.pageX - offset.left, 
                        y : this.pageY - offset.top, 
                        color : $("#color").css("background-color"),
						size: parseInt($("#width").val())
                       };
        });
      }
      event.preventDefault();
    },

    draw: function(event) {
      if (event.type == "mousemove") {
        if (!drawing) {
          return;
        }

        var id = 0;
        moveX = this.pageX - offset.left - event.x;
        moveY = this.pageY - offset.top - event.y;
        var ret = self.move(0, moveX, moveY);
        updateBounds(ctxt, ret);
        lines[0].x = ret.x;
        lines[0].y = ret.y;
      } else {
        var e = event;
        $.each(event.touches, function(i, touch) {
          var id = touch.identifier,
              moveX = this.pageX - offset.left - lines[id].x,
              moveY = this.pageY - offset.top - lines[id].y;
          var ret = self.move(id, moveX, moveY);
          updateBounds(ctxt, ret);
          lines[id].x = ret.x;
          lines[id].y = ret.y;
        });
      }
      event.preventDefault();
    },

    move: function(i, changeX, changeY) {
	  moved = true;
	  if (usingEraser) {
		lines[i].color = "#fff";
	  }
	  drawLine(ctxt, lines[i].x, lines[i].y, changeX, changeY, lines[i].size, lines[i].color);
	  
	  // save lines to undo stack
	  var toLineDraw = { x: lines[i].x, y: lines[i].y, 
						changeX: changeX, changeY: changeY,
						color: ctxt.strokeStyle,
						size: lines[i].size };
	  lineDrawData.push(toLineDraw);

      return { x: lines[i].x + changeX, y: lines[i].y + changeY};
    },
  };
  return self.init();
};

function updateBounds(ctxt, ret) {
  Mx = Math.max(Mx, ret.x + ctxt.lineWidth);
  Mx = Math.min(Mx, canvas.width);  
  My = Math.max(My, ret.y + ctxt.lineWidth);
  My = Math.min(My, canvas.height);  
  mx = Math.min(mx, ret.x - ctxt.lineWidth);
  mx = Math.max(mx, 0);  
  my = Math.min(my, ret.y - ctxt.lineWidth);
  my = Math.max(my, 0);  
}

function clearCanvas() {
	var canvas = document.getElementById("sketchpad"),
	ctxt = canvas.getContext("2d");
	ctxt.fillStyle = "white";
	ctxt.fillRect(0,0,canvas.width, canvas.height); 
}

function redrawFromUndoStack() {
	var canvas = document.getElementById("sketchpad"),
	ctxt = canvas.getContext("2d");
	for (var i = 0; i < undoStack.length; i++) {
		var draw = undoStack[i];
		if (draw.type == "line") {
			for (var j = 0; j < draw.data.length; j++) {
				var lineData = draw.data[j];
				drawLine(ctxt, lineData.x, lineData.y, lineData.changeX, lineData.changeY, lineData.size, lineData.color);
			}
		} else if (draw.type == "point") {
			drawPoint(ctxt, draw.data.x, draw.data.y, draw.data.r, draw.data.color);
		} else if (draw.type == "clear") {
			clearCanvas();
		}
	}
}

function drawPoint(ctxt, centerX, centerY, radius, color) {
	ctxt.beginPath();
	ctxt.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
	ctxt.fillStyle = color;
	ctxt.fill();
	ctxt.closePath();	
}

function drawLine(ctxt, x, y, changeX, changeY, size, color) {
	ctxt.strokeStyle = color;
	ctxt.lineWidth = size;
	ctxt.beginPath();
	ctxt.moveTo(x, y);
	var newX = x + changeX;
	var newY = y + changeY;
	ctxt.lineTo(newX, newY);
	ctxt.stroke();
	ctxt.closePath();
}

$(function(){
  if (testingInBrowser) {
    Musubi._launchCallback();
  }
});
