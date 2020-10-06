package ch2.ui.effects;

import ch2.ui.effects.RichTextEffect;
import ch2.ui.RichText;

class ApearEffectBase extends RichTextEffect {
  
  public var progress:Float = 0;
  public var cps:Float = 30;
  public var appearDuration:Float = .1;
  public dynamic function ease(t:Float):Float return t;
  
  var char:Int;
  var lastDt:Float;
  var progressChar:Int;
  
  override public function reset()
  {
    progress = 0;
    super.reset();
  }
  
  public function delay(time:Float) {
    progress = -time * cps;
  }
  
  override public function begin(ctx:RenderContext)
  {
    char = 0;
    progress += ctx.elapsedTime * cps;
    progressChar = Std.int(progress);
    lastDt = progress - progressChar;
  }
  
  override public function sync(content:RichTextContent, ctx:RenderContext, start:Int, end:Int, node:NodeRange):Bool
  {
    switch (node.node) {
      case NObject(o, advance, isBreak, format):
        applyObject(char <= progressChar ? ease(hxd.Math.clamp((progress - char) / cps / appearDuration)) : 0, o, ctx, node);
        char++;
      default:
        var ch = char;
        for (i in start...end) {
          applyTile(ch <= progressChar ? ease(hxd.Math.clamp((progress - ch) / cps / appearDuration)) : 0, content, ctx, i, node);
          ch++;
        }
        char = ch;
    }
    return true;
  }
  
  override public function end(ctx:RenderContext)
  {
    if (progress > 0) {
      if (char == 0) progress = 0;
      else {
        if (progress > char + 1) {
          // progress = char + 1;
          onFinish();
        }
      }
      // else if (progress > char + 1) progress = 0;
    }
  }
  
  public dynamic function onFinish() {
    
  }
  
  function applyObject(dt:Float, o:Object, ctx:RenderContext, node:NodeRange) {
    
  }
  
  function applyTile(dt:Float, content:RichTextContent, ctx:RenderContext, index:Int, node:NodeRange) {
    
  }
  
}

class SimpleAppear extends ApearEffectBase {
  
  public var alpha:Bool;
  
  public function new(alpha:Bool = true) {
    this.alpha = alpha;
    super();
  }
  
  override function applyObject(dt:Float, o:Object, ctx:RenderContext, node:NodeRange)
  {
    if (alpha) o.alpha = dt;
    else o.alpha = dt < 1 ? 0 : 1;
  }
  
  override function applyTile(dt:Float, content:RichTextContent, ctx:RenderContext, index:Int, node:NodeRange)
  {
    if (alpha) content.mulAlpha(index, dt);
    else content.mulAlpha(index, dt < 1 ? 0 : 1);
  }
  
}

class ShiftAppear extends ApearEffectBase {
  
  public var alpha:Bool;
  var cache:ContentDataCache;
  public var xOff:Float;
  public var yOff:Float;
  
  public function new(xoff:Float = 0, yoff:Float = -5, alpha:Bool = true) {
    this.alpha = alpha;
    this.xOff = xoff;
    this.yOff = yoff;
    cache = new ContentDataCache();
    super();
  }
  
  override public function reset()
  {
    super.reset();
    cache.clear();
  }
  
  override public function begin(ctx:RenderContext)
  {
    cache.idx = 0;
    super.begin(ctx);
  }
  
  override public function init(content:RichTextContent, start:Int, end:Int, node:NodeRange)
  {
    switch (node.node) {
      case NObject(o, advance, isBreak, format):
        cache.add2(o.x, o.y);
      default:
    }
    super.init(content, start, end, node);
  }
  
  override function applyObject(dt:Float, o:Object, ctx:RenderContext, node:NodeRange)
  {
    if (alpha) o.alpha = dt;
    else o.alpha = dt < 1 ? 0 : 1;
    dt = 1 - dt;
    o.x = cache.get() + xOff * dt;
    o.y = cache.get() + yOff * dt;
  }
  
  override function applyTile(dt:Float, content:RichTextContent, ctx:RenderContext, index:Int, node:NodeRange)
  {
    if (alpha) content.mulAlpha(index, dt);
    else content.mulAlpha(index, dt < 1 ? 0 : 1);
    dt = 1 - dt;
    content.offsetXY(index, xOff * dt, yOff * dt);
  }
  
}