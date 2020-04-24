package cherry.plugins.atl;

import hxd.Key;
import h2d.Interactive;
import hxd.Event;
import cherry.plugins.atl.States;
import h2d.col.Point;
import h2d.Object;


class Dragable extends Object {
  
  var drag:Point;
  var localTo:Object;
  
  public var initial:Point;
  public var pos:Point;
  public var restrict:DragRestrict;
  public var cardinalAnchor:Point;
  public var cardinalOffset:Point;
  
  var tempRestrict:DragRestrict;
  
  public function new(parent:Object, localTo:Object) {
    super(parent);
    this.drag = new Point();
    initial = new Point();
    pos = new Point();
    cardinalOffset = new Point();
    restrict = None;
    this.localTo = localTo;
  }
  
  public function start(e:Event, relOrig:Interactive) {
    drag.set(e.relX, e.relY);
    relOrig.localToGlobal(drag);
    syncPos();
    tempRestrict = restrict;
    initial.set(absX, absY);
    onStart();
    getScene().startDrag(onDrag, null, e);
  }
  
  static final PI2 = Math.PI * .5;
  static final PI4 = Math.PI / 4;
  static final PI8 = Math.PI / 8;
  static final CARDINALS = [
    PI8, // 0
    PI4 + PI8, // 45
    PI2 + PI8, // 90
    PI2 + PI4 + PI8 // 135
  ];
  static final DEF_DIAGONALS = [PI4, PI4 + PI2];
  
  function getCardinal() {
    var angle = Math.atan2(absY + cardinalOffset.y - cardinalAnchor.y, absX + cardinalOffset.x - cardinalAnchor.x);
    var mul = if (angle < 0) { angle = -angle; -1; } else 1;
    if (angle < CARDINALS[0]) return 0.;
    else if (angle < CARDINALS[1]) return PI4 * mul;
    else if (angle < CARDINALS[2]) return PI4 * mul;
    else if (angle < CARDINALS[3]) return PI8 * mul;
    else return Math.PI;
  }
  
  function getDiagonal() {
    var angle = Math.atan2(absY + cardinalOffset.y - cardinalAnchor.y, absX + cardinalOffset.x - cardinalAnchor.x);
    var mul = if (angle < 0) { angle = -angle; -1; } else 1;
    return if (angle < 0) angle > -PI2 ? -PI4 : (-PI2 - PI4);
      else angle < PI2 ? PI4 : PI2 + PI4;
  }
  
  function getCardinalIndex(sign:Bool = false) {
    var angle = Math.atan2(absY + cardinalOffset.y - cardinalAnchor.y, absX + cardinalOffset.x - cardinalAnchor.x);
    var mul = if (angle < 0) { angle = -angle; sign ? -1 : 1; } else 1;
    return if (angle < CARDINALS[0]) 0 * mul;
    else if (angle < CARDINALS[1]) 1 * mul;
    else if (angle < CARDINALS[2]) 2 * mul;
    else if (angle < CARDINALS[3]) 3 * mul;
    else 4 * mul;
  }
  
  function onDrag(e:Event) {
    this.x += e.relX - drag.x;
    this.y += e.relY - drag.y;
    drag.set(e.relX, e.relY);
    syncPos();
    if (restrict == NoneSnap) {
      if (Key.isPressed(Key.SHIFT)) {
        switch (getCardinalIndex()) {
          case 0, 4: tempRestrict = Horizontal;
          case 1, 3: tempRestrict = Diagonal;
          default: tempRestrict = Vertical;
        }
      }
      if (Key.isReleased(Key.SHIFT)) {
        tempRestrict = restrict;
      }
    } else if (restrict == NoneAngle) {
      // TODO
    }
    var r = tempRestrict;
    switch (r) {
      case None, NoneSnap, NoneAngle: pos.set(absX, absY);
      case Horizontal: pos.set(absX, initial.y);
      case Vertical: pos.set(initial.x, absY);
      case Diagonal:
        var anchor = cardinalAnchor;
        var dx = absX + cardinalOffset.x - anchor.x;
        var dy = absY + cardinalOffset.y - anchor.y;
        var ang = Math.atan2(dy, dx);
        var aang = Math.abs(ang);
        var mul = ang != aang ? -1 : 1;
        if (aang > PI4 && aang < PI2+PI4) {
          // vertical
          pos.set(anchor.x + dx - cardinalOffset.x, anchor.y + dx * (aang > PI2 ? -mul : mul) - cardinalOffset.y);
        } else {
          // horizontal
          pos.set(anchor.x + dy * (aang > PI2 ? -mul : mul) - cardinalOffset.x, anchor.y + dy - cardinalOffset.y);
        }
      case DiagonalSnap:
        // TODO: One direction snap
    }
    
    localTo.globalToLocal(pos);
    var stop = e.kind == ERelease || e.kind == EReleaseOutside;
    if (stop) getScene().stopDrag();
    onChange(stop);
  }
  
  public dynamic function onStart() { }
  
  public dynamic function onChange(stop:Bool) { }
  
}
