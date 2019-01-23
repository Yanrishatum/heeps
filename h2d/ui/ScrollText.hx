package h2d.ui;
import hxd.Event;
import h2d.Mask;
import h2d.Text;
import h2d.HtmlText;
import h2d.Object;

/**
  Vertically scrollable text container.
  Useful for creation of walls of text.
**/
class ScrollText extends Mask
{
  /**
    Reference to Text instance.
  **/
  public var text:Text;
  /**
    Reference to HtmlText instance if passed one at creation.
  **/
  public var htmlText:HtmlText;
  
  /**
    Maxiumm possible `scrollV` value.
  **/
  public var maxScrollV(get, never):Int;
  /**
    Current scrollV value. Starts at 0, up to maxScrollV.
  **/
  public var scrollV(default, set):Float = 0;
  /**
    Bottom of current scrollV value. Represents bottom of visible Text area.
  **/
  public var bottomScrollV(get, never):Float;
  
  // TODO: ScrollH
  
  public var scrollStep:Float;
  
  var inter:Interactive;
  var dragX:Float;
  var dragY:Float;
  var refV:Float;
  
  public function new(text:Text, width:Int, height:Int, ?parent:Object)
  {
    this.text = text;
    this.htmlText = Std.instance(text, HtmlText);
    super(width, height, parent);
    scrollStep = text.font.lineHeight + text.lineSpacing;
    this.text = text;
    addChild(text);
  }
  
  inline function scrollVLimit():Int
  {
    return Std.int(height / scrollStep);
  }
  
  function get_maxScrollV():Int
  {
    var v = Math.ceil(text.textHeight / scrollStep) - scrollVLimit();
    if (v < 1) return 0;
    return v;
  }
  
  function get_bottomScrollV():Float
  {
    if (text.textHeight < height) return Math.ceil(text.textHeight / scrollStep);
    var bottom:Float = text.y + text.textHeight;
    if (bottom > height) return scrollV + scrollVLimit();
    return scrollV + Math.ceil(bottom / scrollStep);
  }
  
  function set_scrollV(v:Float):Float
  {
    if (v < 0) v = 0;
    else if (v > maxScrollV) v = maxScrollV;
    text.y = -scrollStep * v;
    return scrollV = v;
  }
  
  override private function sync(ctx:RenderContext)
  {
    super.sync(ctx);
    if (inter != null)
    {
      inter.width = this.width;
      inter.height = this.height;
    }
  }
  
  public function hookListeners(mouseDrag:Bool = true):Void
  {
    if (inter == null)
    {
      inter = new Interactive(this.width, this.height, this);
      inter.onWheel = onWheel;
      inter.cursor = Default;
      if (mouseDrag)
      {
        inter.onPush = startMouseDrag;
        inter.onRelease = stopMouseDrag;
      }
    }
  }
  
  public function unhookListeners():Void
  {
    if (inter != null)
    {
      inter.remove();
      inter.onWheel = null;
      inter.onPush = null;
      inter.onRelease = null;
      inter = null;
    }
  }
  
  function startMouseDrag(e:Event):Void
  {
    dragX = e.relX + absX;
    dragY = e.relY + absY;
    refV = scrollV;
    getScene().startDrag(mouseDrag, null, e);
  }
  
  function stopMouseDrag(e:Event):Void
  {
    getScene().stopDrag();
  }
  
  function mouseDrag(e:Event):Void
  {
    var diffY = e.relY - dragY;
    scrollV = refV - (diffY / scrollStep);
  }
  
  function onWheel(e:Event):Void
  {
    scrollV += e.wheelDelta;
  }
  
  
}