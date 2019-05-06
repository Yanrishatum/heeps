package h2d.ui;

import hxd.Event;
import h2d.Tile;

/**
  Primitive checkbox.
  Can be used for fast UI creation for debugging purposes.
**/
class Checkbox extends Interactive
{
  private static var bg:Tile;
  private static var check:Tile;
  
  /**
    Current checkbox state. Does not trigger `onChange` when changed, use `setChecked` function instead if even is required.
  **/
  public var checked:Bool;
  public var label:Text;
  
  public function new(?parent:Object, ?_label:String)
  {
    super(10, 10, parent);
    if (bg == null)
    {
      bg = Tile.fromColor(0x808080, 10, 10);
      var d:hxd.BitmapData = new hxd.BitmapData(8, 8);
      // TODO: Use d.line?
      d.setPixel(7, 1, 0xffCCCCCC);
      d.setPixel(6, 2, 0xffCCCCCC);
      d.setPixel(5, 3, 0xffCCCCCC);
      d.setPixel(4, 4, 0xffCCCCCC);
      d.setPixel(3, 5, 0xffCCCCCC);
      d.setPixel(2, 6, 0xffCCCCCC);
      d.setPixel(1, 5, 0xffCCCCCC);
      d.setPixel(0, 4, 0xffCCCCCC);
      
      check = Tile.fromBitmap(d);
      check.dx = 1;
      check.dy = 1;
    }
    if (_label != null)
    {
      label = new Text(hxd.res.DefaultFont.get(), this);
      label.text = _label;
      label.x = 11;
      this.width = 11 + label.textWidth;
    }
  }
  
  /**
    Sets `checked` flag and triggers `onChange` if value changes.
  **/
  public function setChecked(v:Bool):Void
  {
    if (checked != v)
    {
      checked = v;
      onChange(v);
    }
  }
  
  override private function draw(ctx:RenderContext)
  {
    emitTile(ctx, bg);
    if (checked) emitTile(ctx, check);
  }
  
  override public function handleEvent(e:Event)
  {
    var mdown = mouseDownButton;
    super.handleEvent(e);
    if (e.cancel) return;
    switch(e.kind)
    {
      case ERelease:
        if (mdown == e.button)
        {
          setChecked(!checked);
        }
      default:
    }
  }
  
  public dynamic function onChange(value:Bool):Void
  {
    
  }
}