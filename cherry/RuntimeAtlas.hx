package cherry;

import hxd.Pixels;
import haxe.io.Input;
import haxe.io.BytesInput;
import haxe.io.Path;
import hxd.res.Resource;
#if bin_packing

import binpacking.MaxRectsPacker;
import hxd.res.Image;
import h2d.Tile;
import h3d.mat.Texture;

/**
  Simple runtime atlas generator. For when you want one texture, but don't want to manually build it during development.
  
  As a shortcut, it's possible to utilize `using` and static instance of RuntimeAtlas:
  ```haxe
  class ImageTools {
    static var atlas:RuntimeAtlas = new RuntimeAtlas();
    inline static function toCacheTile(res:hxd.res.Image, dx:Float = 0., dy:Float = 0.) return atlas.get(res, dx, dy);
  }
  ```
**/
class RuntimeAtlas {
  
  public static inline var ATLAS_SIZE:Int = #if enable_large_runtime_atlas 4096 #else 2048 #end ;
  
  var textures:Array<TextureCache>;
  var cache:Map<Image, Tile>;
  
  public function new() {
    textures = [new TextureCache(ATLAS_SIZE)];
  }
  
  #if sys
  public function save(to:String) {
    var texPath = Path.withoutExtension(to);
    var out = sys.io.File.write(Path.withExtension(to, "ratl"));
    out.writeString("RATL");
    out.writeByte(0);
    out.writeByte(0); // ver
    out.writeInt32(ATLAS_SIZE);
    out.writeInt32(textures.length);
    var i = 0;
    var index = [];
    for (t in textures) {
      index.push(t.tex);
      var packer = haxe.Serializer.run(t.packer);
      out.writeInt32(packer.length);
      out.writeString(packer);
      var tio = sys.io.File.write(texPath + "_" + (i++) + ".png");
      new format.png.Writer(tio).write(format.png.Tools.build32BGRA(t.pixels.width, t.pixels.height, t.pixels.bytes));
      tio.close();
    }
    for (kv in cache.keyValueIterator()) {
      var p = kv.key.entry.path;
      out.writeInt32(p.length);
      out.writeString(p);
      out.writeInt32(0);
      var t = kv.value;
      out.writeInt32(index.indexOf(t.getTexture()));
      out.writeInt32(t.ix);
      out.writeInt32(t.iy);
      out.writeInt32(t.iwidth);
      out.writeInt32(t.iheight);
    }
    out.writeInt32(0);
    out.close();
  }
  
  public function load(from:String) {
    var bin = sys.io.File.read(Path.withExtension(from, "ratl"));
    var size = validateCache(bin);
    var count = bin.readInt32();
    for (i in 0...count) {
      var packer = haxe.Unserializer.run(bin.readString(bin.readInt32()));
      var tc = textures[i];
      if (tc == null) textures.push(tc = new TextureCache(size));
      
      var tin = sys.io.File.read(Path.withoutExtension(from) + "_" + i + ".png");
      var d = new format.png.Reader(tin).read();
      format.png.Tools.extract32(d, tc.pixels.bytes);
      tin.close();
      
      tc.packer = packer;
      tc.tex.uploadPixels(tc.pixels);
    }
    fillCache(bin);
    bin.close();
  }
  #end
  
  public function loadRes(ratl:Resource) {
    var bin = new BytesInput(ratl.entry.getBytes());
    var size = validateCache(bin);
    var count = bin.readInt32();
    for (i in 0...count) {
      var img = hxd.Res.load(Path.withoutExtension(ratl.entry.path) + "_" + i + ".png").toImage().getPixels();
      var packer = haxe.Unserializer.run(bin.readString(bin.readInt32()));
      var tc = textures[i];
      if (tc == null) textures.push(tc = new TextureCache(size));
      tc.pixels = img;
      tc.packer = packer;
      tc.tex.uploadPixels(tc.pixels);
    }
    fillCache(bin);
  }
  
  function validateCache(bin:Input) {
    if (bin.readUntil(0) != "RATL") throw "Not a RATL file!";
    var size = bin.readInt32();
    if (ATLAS_SIZE != size) throw "ATLAS_SIZE mismatch!";
    return size;
  }
  
  function fillCache(bin:Input) {
    while (true) {
      var name = bin.readUntil(0);
      if (name == "") break;
      cache[hxd.Res.load(name).toImage()] = @:privateAccess new Tile(textures[bin.readInt32()].tex, bin.readInt32(), bin.readInt32(), bin.readInt32(), bin.readInt32());
    }
  }
  
  public function get(image:Image, dx:Float = 0, dy:Float = 0):Tile {
    var t = cache.get(image);
    if (t == null) {
      var px = image.getPixels();
      for (tc in textures) {
        t = tc.add(px);
        if (t != null) break;
      }
      if (t == null) {
        var tc = new TextureCache(ATLAS_SIZE);
        textures.push(tc);
        t = tc.add(px);
      }
      cache.set(image, t);
    }
    t = t.clone();
    t.dx = dx;
    t.dy = dy;
    return t;
  }
  
}

private class TextureCache {
  
  public var tex:Texture;
  public var tile:Tile;
  public var packer:MaxRectsPacker;
  public var pixels:Pixels;
  
  public function new(size:Int) {
    pixels = Pixels.alloc(size, size, BGRA);
    tex = new Texture(size, size, [Dynamic, NoAlloc], BGRA);
    tile = Tile.fromTexture(tex);
    packer = new MaxRectsPacker(size, size, false);
  }
  
  public function add(px:Pixels):Tile {
    var r = packer.insert(px.width, px.height, BestAreaFit);
    if (r == null) return null;
    pixels.convert(BGRA);
    pixels.blit(Std.int(r.x), Std.int(r.y), px, 0, 0, px.width, px.height);
    tex.uploadPixels(pixels);
    return tile.sub(r.x, r.y, r.width, r.height);
  }
  
}

#end