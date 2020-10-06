package ch2.ui.effects;

import ch2.ui.RichText;

class FilterEffect<T:h2d.filter.Filter> extends RichTextEffect {
  
  public var filter:T;
  
  public function new(filter:T) {
    super();
    this.filter = filter;
  }
  
  override public function attach(content:RichTextRenderer)
  {
    content.filter = filter;
  }
}