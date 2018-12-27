package h2d.ui;
import h2d.Mask;
import h2d.Text;
import h2d.HtmlText;
import h2d.Object;

/**
  Vertically scrollable text container.
**/
class ScrollText extends Mask
{
  
  public var text:Text;
  public var htmlText:HtmlText;
  
  public var maxScrollV(get, never):Int;
  public var scrollV(default, set):Int = 0;
  public var bottomScrollV(get, never):Int;
  
  public var scrollStep:Int;
  
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
  
  function get_bottomScrollV():Int
  {
    if (text.textHeight < height) return Math.ceil(text.textHeight / scrollStep);
    var bottom:Float = text.y + text.textHeight;
    if (bottom > height) return scrollV + scrollVLimit();
    return scrollV + Math.ceil(bottom / scrollStep);
  }
  
  function set_scrollV(v:Int):Int
  {
    if (v < 0) v = 0;
    else if (v > maxScrollV) v = maxScrollV;
    text.y = -scrollStep * v;
    return scrollV = v;
  }
  
  
  
}