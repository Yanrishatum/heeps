package ch2.ui;

import h2d.col.Point;
import h2d.col.Bounds;

/**
  Scrollable container.
**/
class ScrollArea extends Mask
{
  
  /**
    A scroll step when scrolled via `scrollBy`
  **/
  public var scrollStep:Int;
  
  public function new(width:Int, height:Int, scrollStep:Int = 16, ?bounds:Bounds, ?parent:Object)
  {
    super(width, height, parent);
    this.scrollStep = scrollStep;
    this.scrollBounds = bounds;
  }
  
  override public function scrollBy(deltaX:Float, deltaY:Float):Void
  {
    scrollX += deltaX * scrollStep;
    scrollY += deltaY * scrollStep;
  }
  
  public function scrollPixels(x:Float, y:Float):Void
  {
    scrollX += x;
    scrollY += y;
  }
  
  override private function calcAbsPos()
  {
    super.calcAbsPos();
    absX -= scrollX;
    absY -= scrollY;
  }
  
  // override public function localToGlobal(?pt:Point):Point
  // {
  // 	pt = super.localToGlobal(pt);
  // 	pt.x 
  // 	return pt;
  // }
  
  // override public function globalToLocal(pt:Point):Point
  // {
  // 	pt = super.globalToLocal(pt);
  // 	pt.x += scrollX;
  // 	pt.y += scrollY;
  // 	return pt;
  // }
  
  override function drawRec( ctx : h2d.RenderContext ) @:privateAccess {
    if( !visible ) return;
    // fallback in case the object was added during a sync() event and we somehow didn't update it
    if( posChanged ) {
      // only sync anim, don't update() (prevent any event from occuring during draw())
      // if( currentAnimation != null ) currentAnimation.sync();
      calcAbsPos();
      for( c in children )
        c.posChanged = true;
      posChanged = false;
    }
    
    var x1 = absX + scrollX;
    var y1 = absY + scrollY;

    var x2 = width * matA + height * matC + x1;
    var y2 = width * matB + height * matD + y1;

    var tmp;
    if (x1 > x2) {
      tmp = x1;
      x1 = x2;
      x2 = tmp;
    }

    if (y1 > y2) {
      tmp = y1;
      y1 = y2;
      y2 = tmp;
    }

    ctx.flush();
    ctx.pushRenderZone(x1, y1, x2-x1, y2-y1);
    objDrawRec(ctx);
    ctx.flush();
    ctx.popRenderZone();
  }
  
  function objDrawRec(ctx:h2d.RenderContext) {
    if( filter != null && filter.enable ) {
      drawFilters(ctx);
    } else {
      var old = ctx.globalAlpha;
      ctx.globalAlpha *= alpha;
      if( ctx.front2back ) {
        var nchilds = children.length;
        for (i in 0...nchilds) children[nchilds - 1 - i].drawRec(ctx);
        draw(ctx);
      } else {
        draw(ctx);
        for( c in children ) c.drawRec(ctx);
      }
      ctx.globalAlpha = old;
    }
  }
  
}