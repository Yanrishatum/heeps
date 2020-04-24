package cherry.res;

import haxe.io.Path;
import hxd.res.Image;
import hxd.Res;
import haxe.Json;
import hxd.res.Resource;
import cherry.fmt.atl.Data;

@:access(h2d.Tile)
class AtlAtlas extends Resource {
  
  var library:AtlasData;
  
  static var ENABLE_AUTO_WATCH = true;
  
  public function toAtlas():AtlasData {
    if (library != null) return library;
    
    library = new AtlasData();
    library.load(Json.parse(entry.getText()));
    var tile = library.texture = Res.loader.loadCache(library.texturePath, Image).toTile();
    for (s in library.sprites) s.tile = tile.sub(s.x, s.y, s.width, s.height);
    if (ENABLE_AUTO_WATCH) watch(updateAtlas);
    return null;
  }
  
  function updateAtlas() {
    var data = Json.parse(entry.getText());
    var lib = new AtlasData();
    lib.load(data);
    var cur = library;
    if (lib.texturePath != cur.texturePath) {
      var tex = Res.loader.loadCache(cur.texturePath, Image).toTexture();
      cur.texture.innerTex = tex;
      cur.texture.width = tex.width;
      cur.texture.height = tex.height;
    }
    // Sync/add
    var w = cur.texture.width;
    var h = cur.texture.height;
    for (s in lib.sprites) {
      var orig = cur.names[s.fid];
      if (orig == null) {
        cur.addSprite(s);
        s.tile = cur.texture.sub(s.x, s.y, s.width, s.height);
      } else {
        var t = orig.tile;
        t.x = orig.x = s.x;
        t.y = orig.y = s.y;
        t.width = orig.width = s.width;
        t.height = orig.height = s.height;
        t.u = t.x / w;
        t.v = t.y / h;
        t.u2 = (t.x + t.width) / w;
        t.v2 = (t.y + t.height) / h;
      }
    }
    // Remove
    var rem = [];
    for (s in cur.sprites) {
      if (lib.names[s.fid] == null) rem.push(s);
    }
    for (s in rem) lib.removeSprite(s);
    for (a in lib.anims) a.syncTiles();
  }
  
}