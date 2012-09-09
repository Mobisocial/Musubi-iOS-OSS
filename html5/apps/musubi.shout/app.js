/*
 * TicTacToe is the application's main class
 */
function MusuWriter(app) {
  this.appContext = app;
}

var musu;
Musubi.ready(function(context) {
    console.log("launching bigwords.");
    musu = new MusuWriter(context);

    if (musu.appContext.message != null) {
      if (musu.appContext.message.obj != null) {
        var text = musu.appContext.message.obj.data.text;
        console.log("o " + text);
        $("#textbox").val(text);
      }
    }
    
    $("#post").click(function(e) {
      var style = "font-size:30px;padding:5px;";
      style += "background-color:" + $("#textbox").css("background-color") + ";white-space:nowrap;";
      style += "color:" + $("#textbox").css("color") + ";";
      var text = $("#textbox").val()
      var html = '<span style="' + style + '">' + text + '</span>';
      var content = { "__html" : html, "text" : text };
      var obj = new SocialKit.Obj({type : "note", json: content})
      musu.appContext.feed.post(obj);
      musu.appContext.quit();
    });
});

$(function(){
  $("#background div").each(function(i, v){
    $(v).css("background-color", $(v).attr("color"));
    $(v).click(function(e) {
      $("#textbox").css("background-color", $(e.target).attr("color"));
    });
  });

  $("#foreground div").each(function(i, v){
    $(v).css("background-color", $(v).attr("color"));
    $(v).click(function(e) {
      $("#textbox").css("color", $(e.target).attr("color"));
    });
  });
});
