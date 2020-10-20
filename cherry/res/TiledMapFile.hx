package cherry.res;

import hxd.res.Resource;
import haxe.io.Path;
import h2d.Tile;
#if (format_tiled >= "2.0.0" || tiledhx)

#if tiledhx
import tiled.types.TmxMap;
import tiled.types.TmxTileset;
import tiled.types.TmxObject;
import tiled.Tiled;
using tiled.TiledTools;
#else
import format.tmx.Data;
import format.tmx.Reader;
using format.tmx.Tools;

@:structInit
class TiledMapData {
  public var tmx : TmxMap;
  /** Optional list of loaded tilesets when loading map with `loadTilesets = true`. **/
  public var tilesets : Array<TiledMapTileset>;
  
  public function getTileset(gid:Int):TiledMapTileset
  {
    if(gid <= 0) return null;
    var l = this.tilesets.length - 1;
    var i = 0;
    while (i < l)
    {
      if (tilesets[i+1].tileset.firstGID > gid)
        return tilesets[i];
      i++;
    }
    return tilesets[l];
  }
  
  public function getTile(gid:Int):Tile
  {
    if(gid <= 0) return null;
    var l = this.tilesets.length - 1;
    var i = 0;
    while (i < l)
    {
      if (tilesets[i+1].tileset.firstGID > gid)
        return tilesets[i].tileByGid(gid);
      i++;
    }
    return tilesets[l].tileByGid(gid);
  }
}

@:structInit
class TiledMapTileset {
  public var tileset : TmxTileset;
  /**
    List of all tiles in the tileset.
    Note that they are not guaranteed to share the same texture, if tileset is an image set.
  **/
  public var tiles : Array<h2d.Tile>;
  
  public inline function tileByGid(gid:Int):Tile
  {
    return tiles[gid - tileset.firstGID];
  }
  
}

#end

class TiledMapFile extends Resource {

  #if tiledhx
  /**
    The loader used to parse TMX maps, load dependencies and store object types in.
  **/
  public static var loader(get, set):Tiled;
  
  static var _loader:Tiled;
  static inline function get_loader() {
    if (_loader == null) return _loader = new Tiled();
    return _loader;
  }
  static inline function set_loader(v):Tiled {
    return _loader = v;
  }
  
  /**
    Parses TMX file.
    Use TiledMapFile.loader to set the loader configuration and fill object types.
  **/
  public inline function toMap():TmxMap {
    return loader.loadTMXResource(this);
  }
  
  #else
  
  var reader : Reader;
  #if !disable_tsx_cache
  static var tsxCache:Map<String, TmxTileset> = [];
  static var tilesetCache:Map<String, Array<h2d.Tile>> = [];
  #end
  
  /**
    Parses TMX file and optionally resolves TSX references and loads tileset images. objectTypes can be provided to add their properties to objects.
  **/
  public function toMap(resolveTsx = true, loadTilesets = true, ?objectTypes:Map<String, TmxObjectTypeTemplate>) : TiledMapData {

    reader = new Reader();
    if ( resolveTsx ) reader.resolveTSX = loadTsx;
    if ( objectTypes != null ) reader.resolveTypeTemplate = objectTypes.get;

    var tmx = reader.read(Xml.parse(entry.getText()));
    var data : TiledMapData = {
      tmx: tmx,
      tilesets: null
    };
    if ( loadTilesets ) {
      var tilesets = data.tilesets = new Array();
      for ( tset in tmx.tilesets ) {
        var tileset : TiledMapTileset = {
          tileset: tset,
          tiles: new Array()
        };
        #if !disable_tsx_cache
        var cacheName:String = null;
        if (tset.source != null) {
          cacheName = Path.join([entry.directory, tset.source]);
          var cached = tilesetCache.get(cacheName);
          if (cached != null) {
            tileset.tiles = cached;
            tilesets.push(tileset);
            continue;
          }
        }
        #end
        if (tset.image != null && tset.image.source != null) {
          if (haxe.io.Path.isAbsolute(tset.image.source)) throw "Cannot load tileset image with absolute path!";
          var texture = hxd.res.Loader.currentInstance.load(haxe.io.Path.join(tset.source != null ? [entry.directory, tset.source, "..", tset.image.source] : [entry.directory, tset.image.source])).toTexture();
          var x : Int = tset.margin;
          var xmax = texture.width - tset.margin;
          var y : Int = tset.margin;
          var ox = 0;
          var oy = 0;
          if (tset.tileOffset != null) {
            ox = tset.tileOffset.x;
            oy = tset.tileOffset.y;
          }
          for ( i in 0...tset.tileCount ) {
            tileset.tiles.push(@:privateAccess new h2d.Tile(texture, x, y, tset.tileWidth, tset.tileHeight, ox, oy));
            x += tset.tileWidth + tset.spacing;
            if (x >= xmax) {
              x = tset.margin;
              y += tset.tileHeight + tset.spacing;
            }
          }
        } else {
          // Image collection
          for (tile in tset.tiles) {
            if (haxe.io.Path.isAbsolute(tile.image.source)) throw "Cannot load tileset image with absolute path!";
            tileset.tiles.push(hxd.res.Loader.currentInstance.load(haxe.io.Path.join(tset.source != null ? [entry.directory, tset.source, "..", tile.image.source] : [entry.directory, tile.image.source])).toTile());
          }
        }
        #if !disable_tsx_cache
        if (cacheName != null) {
          tilesetCache.set(cacheName, tileset.tiles);
        }
        #end
        tilesets.push(tileset);
      }
    }
    reader = null;
    return data;
  }

  function loadTsx( path : String ) : TmxTileset {
    if (haxe.io.Path.isAbsolute(path)) throw "Cannot load TSX with absolute path!";
    var path = haxe.io.Path.join([entry.directory, path]);
    var tsx;
    #if !disable_tsx_cache
    tsx = tsxCache.get(path);
    if (tsx != null) return tsx;
    #end
    var res = hxd.res.Loader.currentInstance.load(path);
    if ( res != null ) {
      tsx = reader.readTSX(Xml.parse(res.entry.getText()));
      #if !disable_tsx_cache
      tsxCache.set(path, tsx);
      #end
      return tsx;
    }
    throw "Could not find Tsx at path '" + path + "' relative to '" + entry.directory + "'!";
  }
  #end
}

#end
