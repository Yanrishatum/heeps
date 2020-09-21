package ch2.ui.effects;

import ch2.ui.RichText;

class FilterEffect<T:h2d.filter.Filter> extends RichTextEffect {
  
  public var filter:T;
  
  public function new(filter:T) {
    super();
    this.filter = filter;
  }
  
  override public function init(content:BatchDrawer, start:Int, end:Int, node:NodeRange)
  {
    content.invalidateBounds();
  }
  
  override public function attach(content:BatchDrawer)
  {
    content.filter = filter;
  }
}