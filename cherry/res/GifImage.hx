package cherry.res;

import haxe.io.Bytes;
import hxd.PixelFormat;
import hxd.Pixels;
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
  
  var rawGif: {
    width: Int,
    height: Int,
    frames: Array<{ x: Int, y: Int, duration: Float }>
  };
  
  /**
    A helper method to allow reinterpreting of alreayd loaded `hxd.res.Image` as `GifImage`.
  **/
  public static function fromAny(e: hxd.res.Any): GifImage @:privateAccess {
    var res = e.loader.cache.get(e.entry.path);
    if (res != null) {
      if (res is GifImage) return res;
      else if (res is Image) e.loader.cache.remove(e.entry.path);
    }
    return e.to(GifImage);
  }
  
  /**
    Returns Image resource of gif spritesheet.
  **/
  public function toImage():Image
  {
    if (entry.getSign() == 0x46464947)
      return hxd.res.Loader.currentInstance.load(Path.withExtension(".tmp/" + entry.path, "png")).toImage();
    return this;
  }
  
  override public function getInfo():ImageInfo
  {
    if (inf != null) return inf;
    if (entry.getSign() == 0x38464947) {
      // Welp, only way to get proper size is to decode all blocks.
      // Can be sped up by just skimming trough chunk headers.
      inf = new ImageInfo();
      var gif = new format.gif.Reader(new haxe.io.BytesInput(entry.getBytes())).read();
      var fc = format.gif.Tools.framesCount(gif);
      inf.dataFormat = Gif;
      inf.pixelFormat = BGRA;
      inf.width = gif.logicalScreenDescriptor.width;
      inf.height = (gif.logicalScreenDescriptor.height+1)*fc-1;
    }
    return super.getInfo();
  }
  
  override public function getPixels(?fmt:PixelFormat, ?index:Int):Pixels
  {
    if (getInfo().dataFormat == Gif) {
      var gif = new format.gif.Reader(new haxe.io.BytesInput(entry.getBytes())).read();
      var fc = format.gif.Tools.framesCount(gif);
      var fw = gif.logicalScreenDescriptor.width;
      var fh = (gif.logicalScreenDescriptor.height+1) * fc - 1; // spacing to ensure no pixel bleeding
      var h = gif.logicalScreenDescriptor.height;
      var b = Bytes.alloc(fw*fh*fc*4);
      // var pixels = new Pixels(fw, fh, )
      rawGif = {
        width: gif.logicalScreenDescriptor.width,
        height: gif.logicalScreenDescriptor.height,
        frames: []
      };
      var o = 0;
      for (i in 0...fc) {
        var frame = fmt == RGBA ? format.gif.Tools.extractFullRGBA(gif, i) : format.gif.Tools.extractFullBGRA(gif, i);
        var gc = format.gif.Tools.graphicControl(gif, i);
        rawGif.frames.push({ x: 0, y: (h+1)*i, duration: gc.delay/100 });
        b.blit(o, frame, 0, frame.length);
        o += frame.length + fw*4;
      }
      var pixels = new hxd.Pixels(fw, fh, b, fmt == RGBA ? RGBA : BGRA);
      if( fmt != null ) pixels.convert(fmt);
      return pixels;
    }
    return super.getPixels(fmt, index);
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
    } else if (sign == 0x38464947) {
      // Unprocessed .gif
      var tex = toTexture();
      var list: Array<AnimationFrame> = new Array();
      for (f in rawGif.frames) {
        list.push(new AnimationFrame(@:privateAccess new h2d.Tile(tex, f.x, f.y, rawGif.width, rawGif.height), f.duration));
      }
      return list;
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
  #if (sys || nodejs || macro)
  static var __ = hxd.fs.FileConverter.addConfig({
    "fs.convert": {
      "gif": "giff"
    }
  });
  #end
  
}