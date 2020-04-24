package ch2.tiled;

import h2d.Object;
import h2d.SpriteBatch;
import format.tmx.Data;
import cherry.res.TiledMapFile;
import ch2.SpriteBatchExt;

class TilemapLayer extends ch2.TileGroupExt
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
          addTile(ix, iy, cx, cy, tiles[i++]);
          if (++ix == c.width) { ix = 0; iy++; }
        }
      }
    } else {
      tiles = layer.data.tiles;
      while (i < tiles.length)
      {
        addTile(ix, iy, ox, oy, tiles[i++]);
        if (++ix == layer.width) { ix = 0; iy++; }
      }
    }
  }
  
  public function gidAt(x:Int, y:Int):Int {
    if (x < 0 || x >= layer.width || y < 0 || y >= layer.height) return 0;
    return layer.data.tiles[y * layer.width + x].gid;
  }
  
  public function addTile(tx:Int, ty:Int, ox:Float, oy:Float, tile:TmxTile) {
    // TODO: Proper offsets
    // TODO: Render-order
    // TODO: Anything but ortho
    var t = map.getTile(tile.gid);
    if (t != null)
    {
      var sx = 1;
      var sy = 1;
      var x = tx * map.tmx.tileWidth + ox;
      var y = ty * map.tmx.tileHeight + oy;
      if (tile.flippedHorizontally)
      {
        x += t.width;
        sx = -1;
      }
      if (tile.flippedVertically)
      {
        y += t.height;
        sy = -1;
      }
      if (tile.flippedDiagonally)
      {
        x += t.width * sx;
        y += t.height * sy;
        sx *= -1;
        sy *= -1;
      }
      addTransform(x, y, sx, sy, 0, t);
    }
  }
  
}