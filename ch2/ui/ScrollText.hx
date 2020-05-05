package ch2.ui;
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
    Note: Does not invoke onScrollV.
  **/
  public var scrollV(default, set):Float = 0;
  /**
    Bottom of current scrollV value. Represents bottom of visible Text area.
  **/
  public var bottomScrollV(get, never):Float;
  
  // TODO: ScrollH
  
  /**
    Amount of pixels one scroll step uses. Defaults to Text font line height + lineSpacing.
  **/
  public var scrollStep:Float;
  
  var inter:Interactive;
  var dragX:Float;
  var dragY:Float;
  var refV:Float;
  
  public function new(text:Text, width:Int, height:Int, ?parent:Object)
  {
    this.text = text;
    this.htmlText = Std.downcast(text, HtmlText);
    super(width, height, parent);
    scrollStep = text.font.lineHeight + text.lineSpacing;
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
    scrollTextTo(refV - (diffY / scrollStep));
  }
  
  function onWheel(e:Event):Void
  {
    scrollTextBy(e.wheelDelta);
  }
  
  /**
    Shifts current `scrollV` by `steps` and invokes `onScrollV`.
  **/
  public inline function scrollTextBy(steps:Float):Void
  {
    scrollTextTo(scrollV + steps);
  }
  
  /**
    Sets `scrollV` and invokes `onScrollV`.
  **/
  public function scrollTextTo(v:Float):Void
  {
    var old = scrollV;
    onScrollV(scrollV = v, old);
  }
  
  /**
    Converts provided position in pixels to scroll stepped value.  
    Shortcut to `pixels / scrollStep`
  **/
  public inline function toScrollV(pixels:Float):Float
  {
    return pixels / scrollStep;
  }
  
  public dynamic function onScrollV(v:Float, oldV:Float):Void
  {
    
  }
  
  
}