package h2d.ui;

import h2d.Tile;
import h2d.Text;
import hxd.Event;

/**
  Primitive Button with label.
  Can be used for fast UI creation for debugging purposes.
**/
class Button extends Interactive
{
  private var bg:Tile;
  private var hover:Tile;
  private var down:Tile;
  
  private var pressed:Bool;
  
  public function new(w:Int, h:Int, label:String, ?parent:Object)
  {
    super(w, h, parent);
    var txt:Text = new Text(hxd.res.DefaultFont.get(), this);
    txt.maxWidth = w;
    txt.textAlign = Align.Center;
    txt.text = label;
    txt.x = 0;
    txt.y = (h - txt.textHeight) / 2;
    txt.color.setColor(0xffffffff);
    
    bg = Tile.fromColor(0x808080, w, h);
    hover = Tile.fromColor(0xA0A0A0, w, h);
    down = Tile.fromColor(0x606060, w, h);
    
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
