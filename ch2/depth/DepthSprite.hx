package ch2.depth;

import h2d.RenderContext;
import h2d.Layers;
import h2d.Object;
/**
  Small experimental Object that exposes the self-sorting methods.
  
  The sorting is based on 2 parameters: layer and depth. Rendering priority is the folowing:
  Lower layer value rendered first.
  Inside the layer, higher depth value rendered first (i.e. it's further from camera)
**/
class DepthSprite extends Object {
  
  var _layers:Layers;
  var _layer:Int = 0;
  var _depth:Float = 0;
  var _depthDirty:Bool;
  public var drawLayer(get, set):Int;
  public var depth(get, set):Float;
  
  // var _nextDepth:DepthSprite;
  // var _prevDepth:DepthSprite;
  public var subSprites:Array<DepthOffset> = [];
  public var handleSubSpritesScene:Bool = true;
  
  public function new(?parent:Object, layer:Int = 0, depth:Float = 0) {
    this._depth = depth;
    this._layer = layer;
    super(null);
    if (parent != null) {
      var l = Std.downcast(parent, Layers);
      if (l != null) l.add(this, layer);
      else parent.addChild(this);
    }
  }
  
  public function setDepth(depth:Float, ?layer:Int) {
    _depth = depth;
    if (layer != null) {
      if (_layer != layer) {
        _layer = layer;
        // if (_layers != null) _layers.add(this, layer);
      }
    }
    // for (s in subSprites) s.sprite.setDepth(_depth + s.depth, _layer + s.layer);
    _depthDirty = true;
  }
  
  public function addSubSprite(sprite:DepthSprite, depth:Float, layer:Int=0) {
    for (s in subSprites) if (s.sprite == sprite) {
      s.depth = depth;
      s.layer = layer;
      sprite.setDepth(_depth + depth, _layer + layer);
      return;
    }
    this.subSprites.push({ sprite: sprite, depth: depth, layer: layer });
    sprite.setDepth(_depth + depth, _layer + layer);
    if (handleSubSpritesScene && parent != sprite.parent) {
      if (_layers != null) _layers.add(sprite, _layer);
      else parent.addChild(sprite);
    }
  }
  
  override function onAdd()
  {
    _layers = Std.downcast(parent, Layers);
    // this._layer = _layers.getChildLayer(this);
    setDepth(_depth);
    if (handleSubSpritesScene) {
      if (_layers != null) {
        for (s in subSprites) if (s.sprite.parent != parent) _layers.add(s.sprite, _layer);
      } else {
        for (s in subSprites) if (s.sprite.parent != parent) parent.addChild(s.sprite);
      }
    }
    super.onAdd();
  }
  
  override function onRemove()
  {
    _layers = null;
    super.onRemove();
    if (handleSubSpritesScene) {
      for (s in subSprites) s.sprite.remove();
    }
  }
  
  inline function shiftChildrenLeft(from:Int, to:Int) {
    // 0, 1, 2, 3, 4
    //    ^        ^
    // 0, 2, 2, 3, 4
    //       ^     ^
    // 0, 2, 3, 3, 4
    //          ^  ^
    // 0, 2, 3, 4, 4
    //             ^
    while (from < to) {
      parent.children[from] = parent.children[from+1];
      from++;
    }
  }
  
  inline function shiftChildrenRight(from:Int, to:Int) {
    // 0, 1, 2, 3, 4
    // ^        ^
    // 0, 1, 2, 2, 4
    // ^     ^
    // 0, 1, 1, 2, 4
    // ^  ^
    // 0, 0, 1, 2, 4
    // ^
    while (to > from) {
      parent.children[to] = parent.children[to-1];
      to--;
    }
  }
  
  static function childrenSort(a:Object, b:Object) {
    var da = Std.downcast(a, DepthSprite);
    var db = Std.downcast(b, DepthSprite);
    if (da != null && db != null) {
      return depthSort(da, db);
    } else {
      if (da != null) da._depthDirty = false;
      else if (db != null) db._depthDirty = false;
      return 0;
    }
  }
  
  static function layersSort(a:Object, b:Object, min:Int, max:Int) {
    var idx = a.parent.children.indexOf(a, min);
    if (idx == -1 || idx >= max) return 0;
    idx = b.parent.children.indexOf(b, min);
    if (idx == -1 || idx >= max) return 0;
    return inline childrenSort(a, b);
  }
  
  static inline function depthSort(da:DepthSprite, db:DepthSprite) {
    da._depthDirty = false;
    db._depthDirty = false;
    return da._layer == db._layer ? (db._depth == db._depth ? 0 : (da._depth > db._depth ? -1 : 1)) : da._layer - db._layer;
  }
  
  function sortSelf(start:Int, end:Int) {
    end--;
    while (start < end) {
      var child = Std.downcast(parent.children[start], DepthSprite);
      // Sort only against DepthSprites
      // If the child layer is higher, immediately stop (no point going further)
      // If the child depth is lower - stop.
      if (child != this && child != null &&
          (child._layer > _layer || (child._layer == _layer && child.depth < _depth))) {
        break;
      }
      start++;
    }
    // Shift children to reinsert ourselves.
    if (parent.children[start]!=this) {
      var idx = parent.children.indexOf(this);
      if (idx>start) {
        // T, 1, 2, 3, C
        // C, T, 1, 2, 3
        shiftChildrenRight(start, idx);
      } else {
        // C, 1, 2, 3, T
        // 1, 2, 3, T, C
        shiftChildrenLeft(idx, start);
      }
      parent.children[start]=this;
    }
  }
  
  inline function get_drawLayer() return _layer;
  inline function set_drawLayer(v:Int) {
    if (_layer != v) {
      _layer = v;
      for (s in subSprites) s.sprite.setDepth(_depth + s.depth, _layer + s.layer);
      _depthDirty = true;
    }
    return v;
  }
  
  inline function get_depth() return _depth;
  inline function set_depth(v:Float) {
    if (_depth != v) {
      _depth = v;
      for (s in subSprites) s.sprite.setDepth(_depth + s.depth, _layer + s.layer);
      _depthDirty = true;
    }
    return v;
  }
  
  override function sync(ctx:RenderContext)
  {
    if (_depthDirty) {
      if (_layers != null) @:privateAccess {
        var idx = _layers.getChildLayer(this);
        haxe.ds.ArraySort.rec(_layers.children, childrenSort, idx==0?0:_layers.layersIndexes[idx-1], _layers.layersIndexes[idx]);
      } else haxe.ds.ArraySort.sort(parent.children, childrenSort);
      // if (_layers != null) @:privateAccess {
      //   sortSelf(_layer==0 ? 0 : _layers.layersIndexes[_layer-1], _layers.layersIndexes[_layer]);
      // } else if (parent != null) {
      //   sortSelf(0, parent.children.length);
      // }
      // _depthDirty = false;
    }
    super.sync(ctx);
  }
  
}

@:structInit
class DepthOffset {
  public var sprite:DepthSprite;
  public var depth:Float;
  public var layer:Int;
}