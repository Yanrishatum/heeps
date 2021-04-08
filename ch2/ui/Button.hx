package ch2.ui;

import h2d.col.Bounds;
import h2d.RenderContext;
import h2d.Object;
import h2d.Interactive;
import h2d.Tile;
import h2d.Text;
import hxd.Event;

/**
  Primitive Button with label.
  Can be used for fast UI creation for debugging purposes.
**/
class Button extends Interactive
{
  public var txt:Text;
  private var bg:Tile;
  private var hover:Tile;
  private var down:Tile;
  
  private var pressed:Bool;
  
  public function new(w:Int = -1, h:Int = -1, label:String, ?parent:Object)
  {
    super(w, h, parent);
    txt = new Text(hxd.res.DefaultFont.get(), this);
    txt.maxWidth = w;
    txt.textAlign = Align.Center;
    txt.text = label;
    if (w == -1) width = w = Math.ceil(txt.textWidth) + 4;
    if (h == -1) height = h = Math.ceil(txt.textHeight) + 4;
    txt.x = 0;
    txt.y = (h - txt.textHeight) / 2;
    txt.color.setColor(0xffffffff);
    
    bg = Tile.fromColor(0x808080, w, h);
    hover = Tile.fromColor(0xA0A0A0, w, h);
    down = Tile.fromColor(0x606060, w, h);
    
  }
  
  public function resize(w = -1., h = -1.) {
    if (w == -1) w = Math.ceil(txt.textWidth) + 4;
    if (h == -1) h = Math.ceil(txt.textHeight) + 4;
    this.width = w;
    this.height = h;
    txt.maxWidth = w;
    txt.y = (h - txt.textHeight) / 2;
    bg.scaleToSize(w, h);
    hover.scaleToSize(w, h);
    down.scaleToSize(w, h);
  }
  
  override function getBoundsRec(relativeTo:Object, out:Bounds, forSize:Bool)
  {
    super.getBoundsRec(relativeTo, out, forSize);
		if( backgroundColor == null && !forSize ) addBounds(relativeTo, out, 0, 0, Std.int(width), Std.int(height));
  }
  
  override private function draw(ctx:RenderContext)
  {
    if (isOver())
    {
      emitTile(ctx, pressed ? down : hover);
    }
    else 
    {
      emitTile(ctx, pressed ? hover : bg);
    }
  }
  
  override public function handleEvent(e:Event)
  {
    if (e.kind == EventKind.EPush)
    {
      pressed = true;
    }
    else if (e.kind == EventKind.ERelease || e.kind == EventKind.EReleaseOutside)
    {
      pressed = false;
    }
    super.handleEvent(e);
  }
  
}
