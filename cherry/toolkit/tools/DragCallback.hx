package cherry.toolkit.tools;

import h2d.Interactive;
import cherry.soup.EventSignal;
import h2d.col.Point;
import hxd.Event;
import h2d.Object;

/**
  A helper class to simplify operation of dragging elements with mouse.
**/
class DragCallback<T:h2d.Object> {
  
  public var owner:T;
  var ox:Float;
  var oy:Float;
  public var dx:Float;
  public var dy:Float;
  
  public var pixelSnap: Bool;
  
  public var onStart = new EventSignal1<DragCallback<T>>();
  public var onDrag = new EventSignal1<DragCallback<T>>();
  public var onEnd = new EventSignal1<DragCallback<T>>();
  public var startX:Float;
  public var startY:Float;
  public var moveX: Float;
  public var moveY: Float;
  
  public var relX: Float;
  public var relY: Float;
  
  public var manual: Bool;
  public var active: Bool;
  public var moveOwner: Bool = true;
  
  public function new(owner:T) {
    this.owner = owner;
  }
  
  public function attachTo(inter:Interactive) {
    inter.onPush = start.bind(_, inter);
    return this;
  }
  function _start(relX: Float, relY: Float, ?eventRelativeTo:Object) {
    var pt = new Point(relX, relY);
    if (eventRelativeTo != null) eventRelativeTo.localToGlobal(pt);
    owner.parent.globalToLocal(pt);
    startX = owner.x;
    startY = owner.y;
    moveX = 0;
    moveY = 0;
    ox = pt.x;
    oy = pt.y;
  }
  
  public function start(e:Event, ?eventRelativeTo:Object) {
    _start(e.relX, e.relY, eventRelativeTo);
    manual = false;
    active = true;
    owner.getScene().startCapture(onEvent, cancelled, e.touchId);
    onStart.dispatch(this);
  }
  
  public function startManual(relX: Float, relY: Float, ?eventRelativeTo:Object) {
    _start(relX, relY, eventRelativeTo);
    manual = true;
    active = true;
    onStart.dispatch(this);
  }
  
  function _move(relX: Float, relY: Float) {
    this.relX = relX;
    this.relY = relY;
    var rel = new Point(relX, relY);
    owner.parent.globalToLocal(rel);
    dx = rel.x - ox;
    dy = rel.y - oy;
    moveX += dx;
    moveY += dy;
    if (moveOwner) {
      if (pixelSnap) {
        owner.x = Math.round(startX + moveX);
        owner.y = Math.round(startY + moveY);
      } else {
        owner.x = startX + moveX;
        owner.y = startY + moveY;
      }
    }
    ox = rel.x;
    oy = rel.y;
  }
  
  public function moveManual(relX: Float, relY: Float) {
    _move(relX, relY);
    onDrag.dispatch(this);
  }
  
  public function stop() {
    owner.getScene().stopCapture();
  }
  
  function onEvent(e:Event) {
    if (e.kind == ERelease || e.kind == EReleaseOutside) {
      owner.getScene().stopCapture();
    } else if (e.kind == EMove) {
      _move(e.relX, e.relY);
      onDrag.dispatch(this);
    }
  }
  
  function cancelled() {
    active = false;
    onEnd.dispatch(this);
  }
  
  public function stopManual() {
    active = false;
    onEnd.dispatch(this);
  }
  
  
}