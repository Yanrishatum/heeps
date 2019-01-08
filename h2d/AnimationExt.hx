package h2d;

import h2d.Animation;

class AnimationExt extends Animation
{
  
  public var animations:Map<String, AnimationDescriptor> = new Map();
  var current:AnimationDescriptor;
  public var currentAnimation(default, null):String;
  
  var commands:List<AnimationCommand> = new Array();
  
  var wait:Float = 0;
  
  public function addCommand(cmd:AnimationCommand):Void
  {
    commands.add(cmd);
  }
  
  public function resetCommands():Void
  {
    commands.clear();
    wait = 0;
  }
  
  public function playAnim(name:String, atFrame:Int = -1):Void
  {
    if (currentAnimation == name && atFrame == -1) return;
    var desc = animations.get(name);
    if (desc != null) {
      currentAnimation = name;
      current = desc;
      this.loop = desc.loop;
      if (desc.speed != null) this.speed = desc.speed;
      play(desc.frames, frame);
      wait = 0;
    }
  }
  
  override private function sync(ctx:RenderContext)
  {
    if (wait > 0 && (visible || playWhenHidden)) {
      wait -= ctx.elapsedTime * speed;
      if (wait <= 0) {
        wait = 0;
        nextCommand();
      }
    }
    super.sync(ctx);
  }
  
  override private function _onAnimEnd()
  {
    if (current != null && current.next != null)
    {
      playAnim(current.next, current.nextFrame);
    }
    // Ignore loops when Delay active.
    // Chain animations do not trigger command selector.
    else if (wait == 0)
    {
      nextCommand();
    }
    super._onAnimEnd();
  }
  
  function nextCommand():Void
  {
    var readNext:Bool;
    do {
      var cmd = commands.pop();
      readNext = cmd != null && executeCommand(cmd);
    } while(readNext);
  }
  
  function executeCommand(cmd:AnimationCommand):Bool
  {
    switch(cmd)
    {
      case Delay(t):
        wait = t;
        return t == 0;
      case SwitchTo(name, frame):
        var frames = animations.get(name);
        if (frames != null) play(frames, frame);
        else return true;
      case Jump(frame):
        this.palyAt(frame);
      case Pause:
        this.pause = true;
        return true;
      case Reset:
        this.palyAt(0);
      case SetLoop(loop):
        this.loop = loop;
        return true;
      case SetSpeed(speed):
        this.speed = speed;
        return true;
      case Event(name):
        onEvent(name);
        return true;
      case Chain(list):
        for (c in list) executeCommand(c);
    }
    return false;
  }
  
}

class AnimationDescriptor
{
  
  public var frames:Array<AnimationFrame>;
  
  public var loop:Bool;
  public var speed:Null<Float>;
  public var next:String;
  public var nextFrame:Int = -1;
  
  public function new(frames:Array<AnimationFrame>)
  {
    this.frames = frames;
  }
  
}

enum AnimationCommand 
{
  Delay(time:Float);
  SwitchTo(name:String, frame:Int);
  Jump(frame:Int);
  Pause;
  Reset;
  SetLoop(loop:Bool);
  SetSpeed(speed:Float);
  Event(name:String);
  Chain(commands:Array<AnimationCommand>);
}