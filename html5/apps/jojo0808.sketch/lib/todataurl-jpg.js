var tdu = HTMLCanvasElement.prototype.toDataURL;
HTMLCanvasElement.prototype.toDataURL = function(type)
{
 var res = tdu.apply(this,arguments);
 //If toDataURL fails then we improvise
 if(res.substr(0,6) == "data:,")
 {
  var encoder = new JPEGEncoder(90);
  return encoder.encode(this.getContext("2d").getImageData(0,0,this.width,this.height),90);
 }
 else return res;
}
