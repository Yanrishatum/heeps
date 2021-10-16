package ch2.tiled;

import h2d.col.Point;
import h2d.Object;
import h2d.SpriteBatch;
import ch2.SpriteBatchExt;
#if tiledhx
import tiled.types.TmxLayer;
import tiled.types.TmxMap;
using tiled.TiledTools;

class TilemapLayer extends ch2.BatchDrawer {
  
  public var map:TmxMap;
  public var layer:TmxLayer;
  
  public function new (map:TmxMap, layer:TmxLayer, ?parent:Object) {
    this.map = map;
    this.layer = layer;
    super(parent);
    for (c in layer.tileChunks) {
      addChunk(c);
    }
    // TODO: Animations
  }
  
  // public function gidAt(x:Int, y:Int):Int {
  //   if (x < 0 || x >= layer.width || y < 0 || y >= layer.height) return 0;
  //   return layer.data.tiles[y * layer.width + x].gid;
  // }
  public function addChunk(chunk:TileChunk) {
    var tw = map.tileWidth;
    var th = map.tileHeight;
    var ix = 0, iy = 0;
    var tiles = chunk.tiles, i = 0;
    var tsets = map.tilesets;
    switch (map.orientation) {
      case Orthogonal:
        var cx = chunk.x * tw + layer.offsetX;
        var cy = chunk.y * th + layer.offsetY;
        while (i < tiles.length) {
          var gid = tiles[i++];
          if (gid != 0) {
            var t = tsets.getImage(gid);
            var x = cx + ix * tw;
            var y = cy + iy * th + th - t.height;
            if (gid.flippedHorizontally) addTransform(x + t.width, y, -1, 1, 0, t);
            else if (gid.flippedVertically) addTransform(x, y + t.height, 1, -1, 0, t);
            else if (gid.flippedDiagonally) addTransform(x + t.width, y + t.height, -1, -1, 0, t);
            else add(x, y, t);
          }
          if (++ix == chunk.width) { iy++; ix = 0; }
        }
      case Isometric:
        var isoW = tw >> 1;
        var isoH = th >> 1;
        
        var cx = (chunk.x - chunk.y) * isoW + layer.offsetX;
        var cy = (chunk.x + chunk.y) * isoH + layer.offsetY;
        while (i < tiles.length) {
          var gid = tiles[i++];
          if (gid != 0) {
            var t = tsets.getImage(gid);
            var x = cx + (ix - iy) * isoW;
            var y = cy + (ix + iy) * isoH + th - t.height;
            if (gid.flippedHorizontally) addTransform(x + t.width, y, -1, 1, 0, t);
            else if (gid.flippedVertically) addTransform(x, y + t.height, 1, -1, 0, t);
            else if (gid.flippedDiagonally) addTransform(x + t.width, y + t.height, -1, -1, 0, t);
            else add(x, y, t);
          }
          if (++ix == chunk.width) { iy++; ix = 0; }
        }
      case Staggered(staggerYAxis, staggerIndexOdd):
        var staggerX = 0, staggerY = 0, stepX = tw >> 1, stepY = th >> 1;
        var cx = chunk.x * stepX + layer.offsetX;
        var cy = chunk.y * stepY + layer.offsetY;
        if (staggerYAxis) {
          if (staggerIndexOdd) {
            staggerX = tw >> 1;
          } else {
            staggerX = -(tw >> 1);
            cx -= staggerX;
          }
        } else {
          if (staggerIndexOdd) {
            staggerY = th >> 1;
          } else {
            staggerY = -(tw >> 1);
            cy -= staggerY;
          }
        }
        cx += (chunk.x % 2) * staggerX;
        cy += (chunk.y % 2) * staggerY;
        while (i < tiles.length) {
          var gid = tiles[i++];
          if (gid != 0) {
            var t = tsets.getImage(gid);
            var x = cx + ix * stepX + staggerX * (ix % 1);
            var y = cy + iy * stepY + th - t.height;
            if (gid.flippedHorizontally) addTransform(x + t.width, y, -1, 1, 0, t);
            else if (gid.flippedVertically) addTransform(x, y + t.height, 1, -1, 0, t);
            else if (gid.flippedDiagonally) addTransform(x + t.width, y + t.height, -1, -1, 0, t);
            else add(x, y, t);
          }
          if (++ix == chunk.width) { iy++; ix = 0; }
        }
      case Hexagonal(sideLength, staggerYAxis, staggerIndexOdd):
        var staggerX = 0, staggerY = 0, stepX, stepY;
        var cx, cy;
        if (staggerYAxis) {
          stepX = tw;
          stepY = (th + sideLength) >> 1;
          cx = chunk.x * stepX + layer.offsetX;
          cy = chunk.y * stepY + layer.offsetY;
          if (staggerIndexOdd) {
            staggerX = tw >> 1;
          } else {
            staggerX = -(tw >> 1);
            cx -= staggerX;
          }
        } else {
          stepX = (tw + sideLength) >> 1;
          stepY = th;
          cx = chunk.x * stepX + layer.offsetX;
          cy = chunk.y * stepY + layer.offsetY;
          if (staggerIndexOdd) {
            staggerY = th >> 1;
          } else {
            staggerY = -(tw >> 1);
            cy -= staggerY;
          }
        }
        cx += (chunk.x % 2) * staggerX;
        cy += (chunk.y % 2) * staggerY;
        while (i < tiles.length) {
          var gid = tiles[i++];
          if (gid != 0) {
            var t = tsets.getImage(gid);
            var x = cx + ix * stepX;
            var y = cy + iy * stepY + th - t.height;
            if (gid.flippedHorizontally) addTransform(x + t.width, y, -1, 1, 0, t);
            else if (gid.flippedVertically) addTransform(x, y + t.height, 1, -1, 0, t);
            else if (gid.flippedDiagonally) addTransform(x + t.width, y + t.height, -1, -1, 0, t);
            else add(x, y, t);
          }
          if (++ix == chunk.width) { iy++; ix = 0; }
        }
    }
  }
  
  
  public function addTile(tx:Int, ty:Int, ox:Float, oy:Float, gid:TmxTileIndex) {
    if (gid == 0) return;
    var t = map.tilesets.getImage(gid);
    if (t != null) {
      var x, y;
      switch (map.orientation) {
        case Orthogonal:
          x = tx * map.tileWidth + ox;
          y = ty * map.tileHeight + oy;
        case Isometric:
          x = (tx - ty) * (map.tileWidth >> 1) + ox;
          y = (tx + ty) * (map.tileHeight >> 1) + oy;
        case Staggered(staggerYAxis, staggerIndexOdd):
          if (staggerYAxis) {
            y = ty * (map.tileHeight >> 1);
            if (staggerIndexOdd)
              x = tx * map.tileWidth + (tx % 2) * (map.tileWidth >> 1);
            else
              x = tx * map.tileWidth + ((tx + 1) % 2) * (map.tileWidth >> 1);
          } else {
            x = tx * (map.tileWidth >> 1);
            if (staggerIndexOdd)
              y = ty * map.tileHeight + (tx % 2) * (map.tileHeight >> 1);
            else
              y = ty * map.tileHeight + ((tx + 1) % 2) * (map.tileHeight >> 1);
          }
        case Hexagonal(sideLength, staggerYAxis, staggerIndexOdd):
          if (staggerYAxis) {
            y = ty * ((map.tileHeight + sideLength) >> 1);
            if (staggerIndexOdd)
              x = tx * map.tileWidth + (tx % 2) * (map.tileWidth >> 1);
            else
              x = tx * map.tileWidth + ((tx + 1) % 2) * (map.tileWidth >> 1);
          } else {
            x = tx * ((map.tileWidth + sideLength) >> 1);
            if (staggerIndexOdd)
              y = ty * map.tileHeight + (tx % 2) * (map.tileHeight >> 1);
            else
              y = ty * map.tileHeight + ((tx + 1) % 2) * (map.tileHeight >> 1);
          }
      }
      if (gid.flippedHorizontally) addTransform(x + t.width, y, -1, 1, 0, t);
      else if (gid.flippedVertically) addTransform(x, y + t.height, 1, -1, 0, t);
      else if (gid.flippedDiagonally) addTransform(x + t.width, y + t.height, -1, -1, 0, t);
      else add(x, y, t);
    }
  }
  
  
}

#else
import format.tmx.Data;
import cherry.res.TiledMapFile;

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
#end
