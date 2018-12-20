package h2d;

import hxd.Timer;

// Adapted from openfl.display.FPS
class FPS extends Object
{
  
  public var currentFPS(default, null):Int;
  
  var previousFrameCount:Int;
  var stats:Text;
  var deltas:List<Float>;
  
  public function new(?parent:Object)
  {
    super(parent);
    currentFPS = 0;
    previousFrameCount = 0;
    stats = new Text(hxd.res.DefaultFont.get(), this);
    deltas = new List();
  }
  
  override private function sync(ctx:RenderContext)
  {
    super.sync(ctx);
    var ts = Timer.lastTimeStamp;
    deltas.add(ts);
    while (deltas.first() < ts - 1)
    {
      deltas.pop();
    }
    
    var frames = deltas.length;
    currentFPS = Math.round((frames + previousFrameCount) / 2);
    
    if (frames != previousFrameCount)
    {
      stats.text = "FPS: " + hxd.Math.fmt(currentFPS);
    }
    // stats.text = Timer.lastTimeStamp + "\n" + Timer.elapsedTime + "\n" + Timer.frameCount + "\n" + Timer.dt + "\n" + Timer.tmod + "\n" + Timer.fps();
    previousFrameCount = frames;
  }
  
}