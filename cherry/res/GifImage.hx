package cherry.res;

import hxd.res.Image;
import h2d.Object;
import haxe.io.Path;
import ch2.Animation;
import hxd.res.Resource;

/**
  A .gif image resource.
**/
class GifImage extends Resource {
  
  /**
    Returns Image resource of gif spritesheet.
  **/
  public function toImage():Image
  {
    return hxd.res.Loader.currentInstance.load(Path.withExtension(".tmp/" + entry.path, "png")).toImage();
  }
  
  /**
    Returns list of animation frames containing full gif animation.
  **/
  public function toFrames():Array<AnimationFrame>
  {
    var rd = new haxe.io.BytesInput(entry.getBytes());
    if (rd.readString(4) != "GIFF") throw "Invalid header!";
    rd.position += 2; // version
    var frames = rd.readUInt16();
    var width = rd.readInt32();
    var height = rd.readInt32();
    var img = hxd.res.Loader.currentInstance.load(Path.withExtension(".tmp/" + entry.path, "png")).toTexture();
    
    var list:Array<AnimationFrame> = new Array();
    while (frames > 0)
    {
      list.push(new AnimationFrame(@:privateAccess new h2d.Tile(img, rd.readInt32(), rd.readInt32(), width, height), rd.readInt32() / 1000));
      frames--;
    }
    return list;
  }
  
  /**
    Returns an Animation object with frames contained in gif file.
  **/
  public inline function toAnimation(?parent:Object):Animation
  {
    return new Animation(toFrames(), parent);
  }
  
  static var _ = hxd.fs.Convert.register(new cherry.fs.Convert.GifConvert());
  static var __ = hxd.fs.FileConverter.addConfig({
    "fs.convert": {
      "gif": "giff"
    }
  });
  
}