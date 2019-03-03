package h2d.tiled;

import h2d.SpriteBatch;
import format.tmx.Data;
import hxd.res.TiledMapFile;
import h2d.SpriteBatchExt;

class TilemapLayer extends SpriteBatchExt
{
  
  var map:TiledMapData;
  var layer:TmxTileLayer;
  
  public function new(map:TiledMapData, layer:TmxTileLayer, ?parent:Object)
  {
    this.map = map;
    this.layer = layer;
    super(parent);
    var ox = layer.x + layer.offsetX;
    var oy = layer.y + layer.offsetY;
    
    inline function tileAt(tx:Int, ty:Int, ox:Float, oy:Float, tile:TmxTile)
    {
      // TODO: Proper offsets
      // TODO: Render-order
      var t = map.getTile(tile.gid);
      if (t != null)
      {
        var b = alloc(t);
        b.x = tx * map.tmx.tileWidth + ox;
        b.y = ty * map.tmx.tileHeight + oy;
        if (tile.flippedHorizontally)
        {
          b.x += b.t.width;
          b.scaleX = -1;
        }
        if (tile.flippedVertically)
        {
          b.y += b.t.height;
          b.scaleY = -1;
        }
        if (tile.flippedDiagonally)
        {
          b.x += b.t.width * b.scaleX;
          b.y += b.t.height * b.scaleY;
          b.scaleX *= -1;
          b.scaleY *= -1;
        }
      }
    }
    
    var ix = 0, iy = 0;
    var i = 0;
    var tiles:Array<TmxTile>;
    if (layer.data.chunks != null) {
      for (c in layer.data.chunks)
      {
        var cx = ox + c.x * map.tmx.tileWidth;
        var cy = oy + c.y * map.tmx.tileHeight;
        ix = 0; iy = 0;
        i = 0;
        tiles = c.tiles;
        while (i < tiles.length)
        {
          tileAt(ix, iy, cx, cy, tiles[i++]);
          if (++ix == c.width) { ix = 0; iy++; }
        }
      }
    } else {
      tiles = layer.data.tiles;
      while (i < tiles.length)
      {
        tileAt(ix, iy, ox, oy, tiles[i++]);
        if (++ix == layer.width) { ix = 0; iy++; }
      }
    }
  }
  
}