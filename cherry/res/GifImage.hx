package cherry.res;

import haxe.io.BytesInput;
import hxd.res.Image;
import h2d.Object;
import haxe.io.Path;
import ch2.Animation;
import hxd.res.Resource;

/**
  A .gif image resource.
**/
class GifImage extends Image {
  
  /**
    Returns Image resource of gif spritesheet.
  **/
  public function toImage():Image
  {
    if (entry.getSign() == 0x46464947)
      return hxd.res.Loader.currentInstance.load(Path.withExtension(".tmp/" + entry.path, "png")).toImage();
    return this;
  }
  
  /**
    Returns list of animation frames containing full gif animation.
  **/
  public function toFrames():Array<AnimationFrame>
  {
    var sign = entry.getSign();
    var rd:BytesInput = new BytesInput(entry.getBytes());
    if (sign == 0x474E5089) {
      rd.position += 8; // PNG header
      rd.bigEndian = true;
      // Skip until we're in GIFF chunk data
      var len = rd.readInt32();
      while (rd.readInt32() != 0x47494646) {
        rd.position += len + 4;
        len = rd.readInt32();
      }
      rd.bigEndian = false;
    } else if (sign == 0x46464947) {
      rd.position += 4; // header
    } else {
      throw "Invalid header!";
    }
    rd.position += 2; // version
    var frames = rd.readUInt16();
    var width = rd.readInt32();
    var height = rd.readInt32();
    var img = toImage().toTexture();
    // var img = hxd.res.Loader.currentInstance.load(Path.withExtension(".tmp/" + entry.path, "png")).toTexture();
    
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