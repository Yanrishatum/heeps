package ch2.ui.effects;

import h2d.col.Point;
import ch2.ui.RichText;

class MovementEffect extends RichTextEffect {
  
  public static function shake(magnitude:Float): Point -> Int -> Void {
    return function(into:Point, index:Int) {
      into.x = (Math.random() - 0.5) * magnitude * 2;
      into.y = (Math.random() - 0.5) * magnitude * 2;
    }
  }
  
  public static function sineY(magnitude:Float, amplitude:Float, offset:Float = 1): Point -> Int -> Void {
    return function(into:Point, index:Int) {
      into.y = (Math.sin((hxd.Timer.lastTimeStamp + index * offset) * magnitude)) * amplitude;
      into.x = 0;
    }
  }
  
  public static function sineX(magnitude:Float, amplitude:Float, offset:Float = 1) {
    return function(into:Point, index:Int) {
      into.x = (Math.sin((hxd.Timer.lastTimeStamp + index * offset) * magnitude)) * amplitude;
      into.y = 0;
    }
  }
  
  var origins:Array<Float>;
  var index:Int = 0;
  var char:Int = 0;
  var pt:Point;
  /**
    Whether to apply movement to the whole block or each character individually.
  **/
  public var individual:Bool;
  public var fps:Float;
  var time:Float;
  var shouldApply:Bool = false;
  
  public function new(individual:Bool = false, fps:Float = 30) {
    super();
    this.fps = fps;
    this.individual = individual;
    pt = new Point();
    reset();
  }
  
  override public function reset()
  {
    time = 1 / fps;
    origins = [];
  }
  
  override public function begin(content:BatchDrawer, ctx:RenderContext)
  {
    index = 0;
    char = 0;
    time += ctx.elapsedTime;
    var ft = 1 / fps;
    if (time > ft) {
      shouldApply = true;
      time %= ft;
    } else {
      shouldApply = false;
    }
  }
  
  override public function init(content:BatchDrawer, start:Int, end:Int, node:NodeRange)
  {
    var buf = content.getBuffer(false);
    final stride = content.getStride();
    var off = start * stride * 4;
    for (i in start...end) {
      origins.push(buf[off  ]);
      origins.push(buf[off+1]);
      off += stride;
      origins.push(buf[off  ]);
      origins.push(buf[off+1]);
      off += stride;
      origins.push(buf[off  ]);
      origins.push(buf[off+1]);
      off += stride;
      origins.push(buf[off  ]);
      origins.push(buf[off+1]);
      off += stride;
    }
    super.init(content, start, end, node);
  }
  
  override public function sync(content:BatchDrawer, ctx:RenderContext, start:Int, end:Int, node:NodeRange)
  {
    if (shouldApply) {
      var buf = content.getBuffer();
      final stride = content.getStride();
      var off = start * stride * 4;
      var idx = index;
      var ch = char;
      var pt = this.pt;
      getMovement(pt, ch);
      for (i in start...end) {
        for (i in 0...4) {
          buf[off    ] = origins[idx++] + pt.x;
          buf[off + 1] = origins[idx++] + pt.y;
          off += stride;
        }
        if (individual) {
          getMovement(pt, ch);
        }
        ch++;
      }
      char = ch;
      index = idx;
    }
    return true;
  }
  
  public dynamic function getMovement(into:Point, index:Int) {
    
  }
  
}