package hxd.res;

import h2d.Object;
import haxe.io.Path;
import h2d.Animation;
import hxd.res.Resource;

class GifImage extends Resource {
  
  public function toImage():Image
  {
    return hxd.res.Loader.currentInstance.load(Path.withExtension(entry.path, "png")).toImage();
  }
  
  public function toFrames():Array<AnimationFrame>
  {
    var rd = new haxe.io.BytesInput(entry.getBytes());
    if (rd.readString(4) != "GIFF") throw "Invalid header!";
    rd.position += 2; // version
    var frames = rd.readUInt16();
    var width = rd.readInt32();
    var height = rd.readInt32();
    var img = hxd.res.Loader.currentInstance.load(Path.withExtension(entry.path, "png")).toTexture();
    
    var list:Array<AnimationFrame> = new Array();
    while (frames > 0)
    {
      list.push(new AnimationFrame(@:privateAccess new h2d.Tile(img, rd.readInt32(), rd.readInt32(), width, height), rd.readInt32() / 1000));
      frames--;
    }
    return list;
  }
  
  public inline function toAnimation(?parent:Object):Animation
  {
    return new Animation(toFrames(), parent);
  }
  
}