package cherry.plugins.atl;

import hxd.Key;
import h2d.Interactive;
import cherry.plugins.atl.States;


class CornerEdit extends Dragable {
  
  public var type:CornerType;
  var ed:SpriteEdit;
  var centered:Bool;
  
  public var inter:Interactive;
  
  public var width:Int;
  public var height:Int;
  public var maxScale:Float = 9999;
  
  public function new(w:Int = 6, h:Int = 6, type:CornerType, parent:SpriteEdit) {
    ed = parent;
    super(parent, ed.ed.tex);
    this.width = w;
    this.height = h;
    this.centered = type != Center;
    this.type = type;
    
    switch (type) {
      case Top, Bottom: restrict = Vertical;
      case Left, Right: restrict = Horizontal;
      case Center: restrict = NoneSnap;
      default:
    }
    
    onChange = (s) -> onChangeT(type, s);
    onStart = () -> onStartT(type);
    inter = new Interactive(1, 1, this);
    inter.onWheel = (e) -> e.propagate = true;
    inter.onPush = (e) -> {
      if (e.button == 0) {
        if (Key.isDown(Key.CTRL)) ed.ed.clone(ed.sprite, e);
        else start(e, inter);
      } else e.propagate = true;
    }
    inter.onClick = (e) -> e.propagate = true;
    inter.enableRightButton = true;
    resync(true);
  }
  
  public dynamic function onStartT(type:CornerType) {}
  public dynamic function onChangeT(type:CornerType, stop:Bool) {}
  
  public function resync(resize:Bool) {
    var scale = ed.ed.currZoom;
    if (resize) {
      var sx = Math.min(scale, maxScale);
      inter.width = width * sx;
      inter.height = height * sx;
      if (centered) {
        inter.setPosition(width * sx * -.5, height * sx * -.5);
      }
      cardinalOffset.set(width * sx * .5, height * sx * .5);
    }
    switch (type) {
      case TopLeft, Center: setPosition(0, 0);
      case TopRight: setPosition(ed.sprite.width * scale, 0);
      case BottomLeft: setPosition(0, ed.sprite.height * scale);
      case BottomRight: setPosition(ed.sprite.width * scale, ed.sprite.height * scale);
      case Top: setPosition(ed.sprite.width * .5 * scale, 0);
      case Right: setPosition(ed.sprite.width * scale, ed.sprite.height * .5 * scale);
      case Bottom: setPosition(ed.sprite.width * .5 * scale, ed.sprite.height * scale);
      case Left: setPosition(0, ed.sprite.height * .5 * scale);
    }
  }
  
}
