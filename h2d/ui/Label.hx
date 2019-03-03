package h2d.ui;
import hxd.Event;
import h2d.Interactive;
import h2d.Text;

class Label extends Interactive
{
  
  public var target:Interactive;
  public var text:Text;
  
  public function new(label:String, ?font:Font, ?align:Align, ?maxW:Float, target:Interactive, ?parent:Object)
  {
    if (font == null) font = hxd.res.DefaultFont.get();
    if (align == null) align = Left;
    this.text = new Text(font);
    text.textAlign = align;
    if (maxW != null) text.maxWidth = maxW;
    text.text = label;
    if (maxW == null) maxW = text.textWidth;
    super(maxW, text.textHeight, parent);
    this.addChild(text);
    this.target = target;
    this.cursor = target.cursor;
  }
  
  override public function handleEvent(e:Event)
  {
    super.handleEvent(e);
    if (!e.cancel)
    {
      if (target != null)
      {
        var oldX = e.relX;
        var oldY = e.relY;
        if (checkBounds(e))
        {
          e.relX = target.width * .5;
          e.relY = target.height * .5;
        }
        else 
        {
          e.relX = -999;
          e.relY = -999;
        }
        target.handleEvent(e);
        e.relX = oldX;
        e.relY = oldY;
      }
    }
  }
  
}