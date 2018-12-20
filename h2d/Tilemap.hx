package h2d;

import haxe.io.Bytes;
import h3d.Buffer;
import h2d.col.Bounds;

class Tilemap extends Drawable
{
  
  public var width(default, null):Int;
  public var height(default, null):Int;
  public var tileWidth(default, null):Int;
  public var tileHeight(default, null):Int;
  var batches:Array<TilesetDisplay>;
  var tiles:Array<Int>;
  var tileCount:Int;
  var tilesets:Array<Tileset>;
  
  public function new(width:Int, height:Int, tileWidth:Int, tileHeight:Int, tilesets:Array<Tileset>, ?parent:Object)
  {
    // TODO: Make it according to Tiled rendering methods.
    this.width = width;
    this.height = height;
    this.tileWidth = tileWidth;
    this.tileHeight = tileHeight;
    this.tilesets = tilesets;
    this.tiles = new Array();
    this.tileCount = width * height;
    this.batches = new Array();
    for (t in tilesets) batches.push(new TilesetDisplay(t));
    
    super(parent);
  }
  
  public function add(x:Int, y:Int, gid:Int)
  {
    var i:Int = 0;
    while (i < tilesets.length)
    {
      var tset = tilesets[i];
      if (gid >= tset.firstId && gid < tset.tiles.length + tset.firstId)
      {
        var idx = y * width + x;
        for (j in 0...batches.length)
        {
          if (i == j)
            batches[j].set(idx, gid - tset.firstId, x * tileWidth, y * tileHeight);
          else 
            batches[j].remove(idx);
        }
        return;
      }
      i++;
    }
  }
  
  
  override private function getBoundsRec(relativeTo:Object, out:Bounds, forSize:Bool)
  {
    super.getBoundsRec(relativeTo, out, forSize);
    addBounds(relativeTo, out, 0, 0, width * tileWidth, height * tileHeight);
  }
  
  override private function sync(ctx:RenderContext)
  {
    super.sync(ctx);
    for (t in batches) t.sync();
  }
  
  override function draw( ctx : RenderContext )
  {
    for (t in batches) t.render(ctx, this);
  }

}

// Optimized SpriteBatch
class TilesetDisplay
{

  var tset:Tileset;
  public var tile : Tile;
  var tmpBuf : hxd.FloatBuffer;
  var buffer : h3d.Buffer;
  var bufferVertices : Int;
  var tileIndex:Array<Int>;
  var tileIds:Array<Int>;
  var tileX:Array<Float>;
  var tileY:Array<Float>;
  var dirty:Bool;

  public function new(tileset:Tileset) {
    this.tset = tileset;
    tile = tileset.source;
    tileIndex = new Array();
    tileIds = new Array();
    tileX = new Array();
    tileY = new Array();
  }
  
  public function remove(index:Int)
  {
    var idx = tileIndex.indexOf(index);
    if (idx != -1)
    {
      tileIds[idx] = -1;
      dirty = true;
    }
  }

  public function set(index:Int, tile:Int, x:Float, y:Float)
  {
    var idx = tileIndex.indexOf(index);
    if (idx == -1)
    {
      tileIndex.push(index);
      tileX.push(x);
      tileY.push(y);
      tileIds.push(tile);
      dirty = true;
    }
    else if (tileIds[idx] != tile)
    {
      tileIds[idx] = tile;
      dirty = true;
    }
  }

  public function sync() {
    if (dirty)
      flush();
  }

  function flush() {
    dirty = false;
    if( tmpBuf == null ) tmpBuf = new hxd.FloatBuffer();
    var pos = 0;
    var i = 0;
    var tmp = tmpBuf;
    while (i < tileIds.length)
    {
      if (tileIds[i] == -1) continue;
      var t = tset.tiles[tileIds[i]];

      tmp.grow(pos + 8 * 4);

      var sx = tileX[i] + t.dx;
      var sy = tileY[i] + t.dy;
      
      inline function fillRgba() {
        tmp[pos++] = 1;
        tmp[pos++] = 1;
        tmp[pos++] = 1;
        tmp[pos++] = 1;
      }
      tmp[pos++] = sx;
      tmp[pos++] = sy;
      tmp[pos++] = t.u;
      tmp[pos++] = t.v;
      fillRgba();
      tmp[pos++] = sx + t.width + 0.1;
      tmp[pos++] = sy;
      tmp[pos++] = t.u2;
      tmp[pos++] = t.v;
      fillRgba();
      tmp[pos++] = sx;
      tmp[pos++] = sy + t.height + 0.1;
      tmp[pos++] = t.u;
      tmp[pos++] = t.v2;
      fillRgba();
      tmp[pos++] = sx + t.width + 0.1;
      tmp[pos++] = sy + t.height + 0.1;
      tmp[pos++] = t.u2;
      tmp[pos++] = t.v2;
      fillRgba();
      i++;
    }
    bufferVertices = pos>>3;
    
    if( buffer != null && !buffer.isDisposed() ) {
      if( buffer.vertices >= bufferVertices ){
        buffer.uploadVector(tmpBuf, 0, bufferVertices);
        return;
      }
      buffer.dispose();
      buffer = null;
    }
    if( bufferVertices > 0 )
      buffer = h3d.Buffer.ofSubFloats(tmpBuf, 8, bufferVertices, [Dynamic, Quads, RawFormat]);
  }

  public function render(ctx:RenderContext, obj:Drawable)
  {
    if( buffer == null || buffer.isDisposed() || bufferVertices == 0 ) return;
    if( !ctx.beginDrawObject(obj, tile.getTexture()) ) return;
    ctx.engine.renderQuadBuffer(buffer, 0, bufferVertices>>1);
  }
  
  public function dispose()
  {
    if (buffer != null)
    {
      buffer.dispose();
      buffer = null;
    }
  }
}

class Tileset
{
  
  public var firstId:Int;
  public var source:Tile;
  public var tiles:Array<Tile>;
  
  public function new(source:Tile, firstId:Int, tileWidth:Int, tileHeight:Int, spacing:Int = 0, margin:Int = 0, dx:Int = 0, dy:Int = 0)
  {
    this.firstId = firstId;
    this.source = source;
    this.tiles = new Array();
    
    var y = margin;
    var x;
    while (y < source.height)
    {
      x = margin;
      while (x < source.width)
      {
        tiles.push(source.sub(x, y, tileWidth, tileHeight, dx, dy));
        x += tileWidth + spacing;
      }
      y += tileHeight + spacing;
    }
    
  }
  
}