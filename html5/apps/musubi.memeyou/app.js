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

Musubi.ready(function(appContext) {
  console.log("Musubi.ready() called");
  canvas = document.getElementById("sketchpad");
  console.log("got canvas");
  var args = {id:"sketchpad", size: parseInt($("#width").val()), color: $("#color").css("background-color") };
  if (appContext.obj != null) {
    var img = Musubi.urlForRawData(appContext.obj.objId);
    console.log("got it " + img);
    if (img != null) {
      args.bg = img;
    }
  }
  console.log("creating MemeYou...");
  sketch = new SketchApp(args); 
             
  $("#caption").keyup(function(e) {
    redraw();           
  });
             
  $("#post").click(function(e) {
    var elm = document.getElementById('sketchpad');
    var copy = document.createElement("canvas");
    var w = Mx - mx;
    var h = My - my;
    var border_h =  Math.min(16, canvas.width - w);  
    var border_v =  Math.min(16, canvas.height - $("#topbar").height() - h);  
    copy.width = w + border_h;
    copy.height = h + border_v;
    var cpx = copy.getContext("2d");
    cpx.fillStyle = "white";
    cpx.fillRect(0,0,copy.width, copy.height);
    cpx.drawImage(elm, mx, my, w, h, border_h / 2, border_v / 2, w, h);
    var snapshot = copy.toDataURL();

    var json = { "mimeType" : "image/jpeg" };
    var obj = new SocialKit.Obj({"type" : "picture", "raw_data_url": snapshot, "json": json });
    if (!testingInBrowser) {
      appContext.feed.post(obj);
      appContext.quit();
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

  $("#confirm-post").click(function() {
    $("#post").trigger("click");
  });
  $("#confirm-discard").click(function() {
    appContext.quit();
  });
  $("#confirm-cancel").click(function() {
    $("#confirm").hide();
  });
  var postDialogVisible = false;
  appContext.setBack(function() {
    if(pickerVisible) {
       pickerVisible = false;
       $("#colorpicker").hide();
       return;
    }
    if(postDialogVisible == false && mx >= Mx && my >= My) {
      appContext.quit();
    }
    $("#confirm").toggle();
  });

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

  var barHeight = $("#topbar").height(); 
  var editableHeight = img.height - barHeight;

  var aspect = img.width / img.height;
  var scaleWidth = canvas.width;
  var scaleHeight = scaleWidth / aspect;
  if (scaleHeight > canvas.height - barHeight) {
    console.log("rescaling from height " + scaleHeight);
    scaleHeight = canvas.height - barHeight;
    scaleWidth = scaleHeight * aspect;
  }
  var sy = (canvas.height - scaleHeight) / 2 + barHeight / 2;
  var sx = 0;

  mx = sx;
  my = sy;
  Mx = scaleWidth + mx; 
  My = scaleHeight + my;

  ctxt.drawImage(img, sx, sy, scaleWidth, scaleHeight);  
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
    $("body").append("<img id='backgroundImage' src='"+options.bg+"' onload='onImageLoaded(this)' style='display:none;' />");
  }
};

function updateBounds(ctxt, ret) {
  Mx = Math.max(Mx, ret.x + ctxt.lineWidth);
  Mx = Math.min(Mx, canvas.width);  
  My = Math.max(My, ret.y + ctxt.lineWidth);
  My = Math.min(My, canvas.height);  
  mx = Math.min(mx, ret.x - ctxt.lineWidth);
  mx = Math.max(mx, 0);  
  my = Math.min(my, ret.y - ctxt.lineWidth);
  my = Math.max($("#topbar").height(), my);
  my = Math.max(my, 0);  
}

function redraw() {
	var canvas = document.getElementById("sketchpad"),
	ctxt = canvas.getContext("2d");
	ctxt.fillStyle = "white";
	ctxt.fillRect(0,0,canvas.width, canvas.height); 
    if ($("#backgroundImage").length > 0) {
        onImageLoaded($("#backgroundImage")[0]);
    }

    var fontFace = "Passion One";
    var text = $("#caption").val();
    var color = $("#color").css("background-color");
    ctxt.font = "32pt " + fontFace;
    ctxt.fillStyle = color;
    ctxt.textBaseline = "top";

    var dim = ctxt.measureText(text);
    var width = Mx - mx;
    var scale = width / dim.width;
    var fontSize = Math.min(32*scale, 50);
    ctxt.font = fontSize + "pt " + fontFace;
    ctxt.fillText(text, 10, my); 
}

$(function(){
  if (testingInBrowser) {
    Musubi._launchCallback();
  }
});
