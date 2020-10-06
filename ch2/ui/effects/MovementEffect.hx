package ch2.ui.effects;

import h2d.col.Point;
import ch2.ui.RichText;
import ch2.ui.effects.RichTextEffect;

class MovementEffect extends RichTextEffect {
  
  public static function shake(magnitude:Float) {
    return function(into:Point, index:Int, time:Float) {
      into.x = (Math.random() - 0.5) * magnitude * 2;
      into.y = (Math.random() - 0.5) * magnitude * 2;
    }
  }
  
  public static function sineY(magnitude:Float, amplitude:Float, offset:Float = 1) {
    return function(into:Point, index:Int, time:Float) {
      into.y = (Math.sin((time + index * offset) * magnitude)) * amplitude;
      into.x = 0;
    }
  }
  
  public static function sineX(magnitude:Float, amplitude:Float, offset:Float = 1) {
    return function(into:Point, index:Int, time:Float) {
      into.x = (Math.sin((time + index * offset) * magnitude)) * amplitude;
      into.y = 0;
    }
  }
  
  var char:Int = 0;
  var pt:Point;
  /**
    Whether to apply movement to the whole block or each character individually.
  **/
  public var individual:Bool;
  public var speed:Float;
  var time:Float;
  
  public function new(individual:Bool = false, speed:Float = 1) {
    super();
    this.speed = speed;
    this.individual = individual;
    pt = new Point();
    reset();
  }
  
  override public function reset()
  {
    time = 0;
  }
  
  override public function begin(ctx:RenderContext)
  {
    char = 0;
    time += ctx.elapsedTime * speed;
  }
  
  override public function sync(content:RichTextContent, ctx:RenderContext, start:Int, end:Int, node:NodeRange)
  {
    var ch = char;
    var pt = this.pt;
    var t = time;
    getMovement(pt, ch, t);
    for (i in start...end) {
      content.offsetXY(i, pt.x, pt.y);
      if (individual) getMovement(pt, ch, t);
      ch++;
    }
    char = ch;
    return true;
  }
  
  public dynamic function getMovement(into:Point, index:Int, time:Float) {
    
  }
  
}