/**
 * Musu Todo
 */

Musubi.ready(function(appContext) {
    console.log("launching musu todo...");

    $("#post").click(function(e) {
      var html = "<ol>";
      $("#todolist .note").each(function(i, v) {
        html += "<li>" + $(v).val() + "</li>";
      });
      html += "</ol>";
      var content = { "__html" : html };
      var obj = new SocialKit.Obj({type : "todolist", data: content})
      appContext.feed.post(obj);
      $("body").html(html);
    });

    $("#add").click(function(event) {
      var text = $("#textbox").val();
      $("#todolist").append('<br/><input class="note" value="' + text + '">');
      $("#textbox").val("");
    });
});

$(function(){
  if (!isMobile()) {
    Musubi._launchCallback();
  }
});

function isMobile() {
 return ( navigator.userAgent.match(/Android/i) ||
 navigator.userAgent.match(/webOS/i) ||
 navigator.userAgent.match(/iPhone/i) ||
 navigator.userAgent.match(/iPod/i) ||
 navigator.userAgent.match(/BlackBerry/)
 );
}