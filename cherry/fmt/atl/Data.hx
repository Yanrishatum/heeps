package cherry.fmt.atl;

import h2d.Anim;
import h2d.Object;
import ch2.Animation;
import h2d.Tile;

class AtlasData {
  
  public var texturePath:String;
  public var texture:Tile;
  
  public var anims:Map<String, AtlasAnim>;
  public var names:Map<String, AtlasSprite>;
  public var sprites:Array<AtlasSprite>;
  
  public function new() {
    anims = [];
    names = [];
    sprites = [];
  }
  
  public inline function get(name:String):AtlasSprite return names[name];
  public inline function getAnim(name:String):AtlasAnim return anims[name];
  public inline function getFrame(anim:String, index:Int):AtlasSprite return anims[anim].sprites[index];
  
  public inline function getTile(name:String):Tile return names[name].tile;
  public inline function getAnimTiles(name:String):Array<Tile> return anims[name].tiles;
  public inline function getAnimTile(anim:String, index:Int):Tile return anims[anim].tiles[index];
  
  #if (!hide_plugin && !cherry_editor) @:noCompletion #end
  public function addSprite(s:AtlasSprite, index:Int = -1) {
    sprites.push(s);
    var anim = anims.get(s.id);
    if (anim == null) {
      anims[s.id] = new AtlasAnim(s.id, [s]);
      names[s.id] = s;
      names[s.fid] = s;
    } else {
      if (index == -1) {
        s.index = anim.length;
        names[s.fid] = s;
        anim.sprites.push(s);
      } else {
        s.index = index;
        names[s.fid] = s;
        anim.sprites.insert(index, s);
        while (++index < anim.length) {
          var n = anim.sprites[index];
          n.index = index;
          names[n.fid] = n;
        }
      }
    }
  }
  
  #if (!hide_plugin && !cherry_editor) @:noCompletion #end
  public function removeSprite(s:AtlasSprite) {
    sprites.remove(s);
    var anim = anims.get(s.id);
    anim.sprites.remove(s);
    if (anim.length == 0) {
      anims.remove(s.id);
      names.remove(s.id);
      names.remove(s.fid);
    } else {
      if (s.index == 0) names[s.id] = anim.sprites[0];
      names.remove(s.id + "#" + anim.length);
      for (i in s.index...anim.length) {
        anim.sprites[i].index--;
        names[anim.sprites[i].fid] = anim.sprites[i];
      }
    }
  }
  
  #if (!hide_plugin && !cherry_editor) @:noCompletion #end
  public function renameSprite(s:AtlasSprite, newId:String) {
    if (s.id == newId) return; // no point
    var anim = anims.get(s.id);
    anim.sprites.remove(s);
    if (anim.length == 0) {
      anims.remove(s.id);
      names.remove(s.id);
      names.remove(s.fid);
    } else {
      if (s.index == 0) names[s.id] = anim.sprites[0];
      names.remove(s.id + "#" + anim.length);
      for (i in s.index...anim.length) {
        anim.sprites[i].index--;
        names[anim.sprites[i].fid] = anim.sprites[i];
      }
    }
    s.id = newId;
    anim = anims.get(newId);
    if (anim == null) {
      s.index = 0;
      anims[newId] = anim = new AtlasAnim(newId, [s]);
      anim.id = newId;
      names[newId] = s;
    } else {
      s.index = anim.length;
      anim.sprites.push(s);
    }
    names[s.fid] = s;
  }
  
  #if (!hide_plugin && !cherry_editor) @:noCompletion #end
  public function renameAnim(anim:AtlasAnim, newId:String) {
    if (anim.id == newId) return; // no point
    var ref = anims.get(newId);
    if (ref != null) {
      throw "Animation name already occupied! " + anim.id + " -> " + newId;
      // TODO ?
    } else {
      anims.remove(anim.id);
      anims.set(newId, anim);
      for (s in anim.sprites) {
        names.remove(s.fid);
        s.id = newId;
        names.set(s.fid, s);
      }
      names.remove(anim.id);
      anim.id = newId;
      names.set(anim.id, anim.sprites[0]);
    }
  }
  
  #if (!hide_plugin && !cherry_editor) @:noCompletion #end
  public function moveSprite(s:AtlasSprite, newIndex:Int) {
    if (s.index == newIndex) return;
    var anim = anims.get(s.id);
    if (newIndex < 0) newIndex = 0;
    else if (newIndex >= anim.length) newIndex = anim.length - 1;
    if (s.index == newIndex) return;
    
    if (hxd.Math.iabs(s.index - newIndex) == 1) {
      // Simple swamp
      var tmp = anim.sprites[s.index];
      anim.sprites[s.index] = anim.sprites[newIndex];
      anim.sprites[newIndex] = tmp;
    } else {
      anim.sprites.remove(s);
      anim.sprites.insert(newIndex, s);
    }
    for (i in 0...anim.length) {
      anim.sprites[i].index = i;
      names[anim.sprites[i].fid] = anim.sprites[i];
    }
    names[s.id] = anim.sprites[0];
  }
  
  public function save() {
    var f = {
      ver: 1,
      texture: texturePath,
      sprites: [for (s in sprites) s.save()],
      anims: [for (kv in anims.keyValueIterator()) ({ 
        id: kv.key,
        sprites:[for(s in kv.value.sprites) sprites.indexOf(s)]
      })]
    };
    return f;
  }
  
  public function load(data:Dynamic) {
    if (data.ver == null) loadV0(data, 0);
    else if (data.ver == 1) loadV0(data, data.ver);
    else {
      throw "Unsupported version: " + data.ver;
    }
  }
  
  public function setTexture(tex:Tile) {
    this.texture = tex;
    for (s in sprites) {
      s.tile = tex.sub(s.x, s.y, s.width, s.height, s.originX, s.originY);
    }
    for (a in anims) a.syncTiles();
  }
  
  function loadV0(data:Dynamic, v:Int) {
    texturePath = data.texture;
    for (s in (data.sprites:Array<Dynamic>)) {
      var s = AtlasSprite.load(s, v);
      sprites.push(s);
      if (s.index == 0) names.set(s.id, s);
      names.set(s.id + "#" + s.index, s);
    }
    for (a in (data.anims:Array<Dynamic>)) {
      anims.set(a.id, new AtlasAnim(a.id, [for (i in (a.sprites:Array<Int>)) sprites[i]]));
    }
  }
  
}

class AtlasAnim {
  
  public var id:String;
  public var sprites:Array<AtlasSprite>;
  public var tiles:Array<Tile>;
  
  public var length(get, never):Int;
  inline function get_length() return sprites.length;
  
  public function new(id:String, sprites:Array<AtlasSprite>) {
    this.id = id;
    this.sprites = sprites;
    this.tiles = [];
    syncTiles();
  }
  
  public function makeFrames():Array<AnimationFrame> {
    return [for (s in sprites) s.toFrame()];
  }
  
  public function makeAnimation(?parent:Object):Animation {
    return new Animation(makeFrames(), parent);
  }
  
  public function makeAnim(speed:Float, ?parent:Object):Anim {
    return new Anim(tiles.copy(), speed, parent);
  }
  
  @:noCompletion public function syncTiles() {
    for (i in 0...sprites.length) {
      tiles[i] = sprites[i].tile;
    }
    while (tiles.length > sprites.length) tiles.pop();
  }
  
}

class AtlasSprite {
  
  public var id:String;
  public var index:Int;
  public var x:Int;
  public var y:Int;
  public var width:Int;
  public var height:Int;
  
  public var originX:Float = 0;
  public var originY:Float = 0;
  public var delay:Float = 0;
  
  public var tile:Tile;
  
  public var fid(get, never):String;
  inline function get_fid() return id + "#" + index;
  
  public static function load(data:Dynamic, ver:Int) {
    var t = new AtlasSprite(data.id);
    t.index = data.index;
    t.x = data.x;
    t.y = data.y;
    t.width = data.width;
    t.height = data.height;
    if (ver > 0) {
      t.originX = data.dx;
      t.originY = data.dy;
      t.delay = data.delay;
    }
    return t;
  }
  
  public function new(id:String) {
    this.id = id;
    index = 0;
  }
  
  public function toFrame(isKey:Bool = true):AnimationFrame {
    return new AnimationFrame(tile, delay, isKey);
  }
  
  public function save() {
    return {
      id: id, index: index,
      x: x, y: y, width: width, height: height,
      dx: originX, dy: originY, delay: delay
    };
  }
  
  #if (hide_plugin || cherry_editor)
  public function clone() {
    var s = new AtlasSprite(id);
    s.x = x;
    s.y = y;
    s.width = width;
    s.height = height;
    s.originX = originX;
    s.originY = originY;
    s.delay = delay;
    return s;
  }
  #end
  
}