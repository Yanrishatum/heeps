package cherry.plugins.atl;

import hxd.Event;
import h2d.RenderContext;
import h2d.col.Bounds;
import h2d.col.Point;
import h2d.Scene;
import h2d.Graphics;
import h2d.Object;


class CreateTool extends Object {
  
  var g:Graphics;
  var s:Scene;
  var ed:AtlasEditor;
  
  var pts:Point;
  var end:Point;
  var b:Bounds;
  var disp:Graphics;
  
  public function new(ed:AtlasEditor, ?parent) {
    super(parent);
    this.ed = ed;
    s = getScene();
    g = new Graphics(this);
    resize();
    // visible = false;
  }
  
  override function sync(ctx:RenderContext)
  {
    x = s.mouseX;
    y = s.mouseY;
    super.sync(ctx);
  }
  
  public function resize() {
    g.beginFill(0xff0000);
    var w = s.width+10, h = s.height+10;
    g.drawRect(-w, 0, w*2, 1);
    g.drawRect(0, -h, 1, h*2);
    g.endFill();
  }
  
  public function start(e:Event) {
    s.startDrag(event, null, e);
    b = new Bounds();
    pts = new Point(e.relX, e.relY);
    ed.tex.globalToLocal(pts);
    end = pts.clone();
    b.addPoint(pts);
    disp = new Graphics(ed.tex);
    ed.toolAction = Create;
  }
  
  function event(e:Event) {
    
    ed.tex.syncPos();
    end.set(e.relX, e.relY);
    ed.tex.globalToLocal(end);
    b.empty();
    b.addPoint(pts);
    b.addPoint(end);
    
    var ib = b.toIBounds();
    disp.clear();
    disp.beginFill(0x00ff00);
    disp.drawRect(ib.x-1, ib.y-1, ib.width+2, 1);
    disp.drawRect(ib.x-1, ib.y+ib.height, ib.width+2,1);
    disp.drawRect(ib.x-1, ib.y, 1, ib.height+1);
    disp.drawRect(ib.x+ib.width, ib.y, 1, ib.height);
    disp.endFill();
    
    if (e.kind == ERelease || e.kind == EReleaseOutside) {
      s.stopDrag();
      disp.remove();
      disp = null;
      ed.toolAction = None;
      ed.createTile(ib);
    }
  }
  
  
}