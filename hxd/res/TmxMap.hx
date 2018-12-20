package hxd.res;

#if (format_tiled >= "2.0.0")

import format.tmx.Data;
import format.tmx.Reader;
using format.tmx.Tools;

typedef TiledMapData = {
var tmx : TmxMap;
  /** Optional list of loaded tilesets when loading map with `loadTilesets = true`. **/
  var tilesets : Array<TiledMapTileset>;
}

typedef TiledMapTileset = {
  var tileset : TmxTileset;
  /**
  	List of all tiles in the tileset.
  	Note that they are not guaranteed to share the same texture, if tileset is an image set.
  **/
  var tiles : Array<h2d.Tile>;
}

class TiledMap extends Resource {

  	var reader : Reader;

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
  			if (tset.image != null && tset.image.source != null) {
  				if (haxe.io.Path.isAbsolute(tset.image.source)) throw "Cannot load tileset image with absolute path!";
  				var texture = hxd.res.Loader.currentInstance.load(haxe.io.Path.join([entry.directory, tset.image.source])).toTexture();
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
  					tileset.tiles.push(hxd.res.Loader.currentInstance.load(haxe.io.Path.join([entry.directory, tset.image.source])).toTile());
  				}
  			}
  			tilesets.push(tileset);
  		}
  	}
  	reader = null;
  	return data;
  }

  	function loadTsx( path : String ) : TmxTileset {
  	if (haxe.io.Path.isAbsolute(path)) throw "Cannot load TSX with absolute path!";
  	var res = hxd.res.Loader.currentInstance.load( haxe.io.Path.join([entry.directory, path]));
  	if ( res != null ) {
  		return reader.readTSX(Xml.parse(res.entry.getText()));
  	}
  	throw "Could not find Tsx at path '" + path + "' relative to '" + entry.directory + "'!";
  }

}

#end