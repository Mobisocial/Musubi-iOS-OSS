/**
 * Displays images from a feed.
 */

Musubi.ready(function(appContext) {
   var objects = appContext.feed.query("type='picture'");
   console.log("retrieved " + objects);
   for (i = 0; i < objects.length; i++) {
     var obj = objects[i];
     $("body").append(obj.objId + ": " + JSON.stringify(obj.json));
     $("body").append("<br/>").append(Musubi.urlForRawData(obj.objId));
     $("body").append("<img src=\""+ Musubi.urlForRawData(obj.objId) +"\"/>");
     $("body").append("<br/>");
   }
});
