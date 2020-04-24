package ch2;

import h2d.RenderContext;
import ch2.Animation;

/**
  Extended version of Animation with named animation storage and primitive command buffer.
  Command buffer triggers next command either when delay timeout runs out or animation reaches it's end.
**/
class AnimationExt extends Animation
{
  
  /**
    List of named animation between which AnimationExt can switch.
  **/
  public var animations:Map<String, AnimationDescriptor> = new Map();
  var current:AnimationDescriptor;
  /**
    Current animation name.
  **/
  public var currentAnimation(default, null):String;
  
  var commands:List<AnimationCommand> = new List();
  
  var wait:Float = 0;
  
  /**
    Adds new command to the end of command buffer.
  **/
  public function addCommand(cmd:AnimationCommand):Void
  {
    commands.add(cmd);
  }
  
  /**
    Clears command buffer.
  **/
  public function resetCommands():Void
  {
    commands.clear();
    wait = 0;
  }
  
  /**
    Plays animation with specified name, and optionally at specific frame.
  **/
  public function playAnim(name:String, ?atFrame:Int):Void
  {
    if (currentAnimation == name && atFrame == null) return;
    var desc = animations.get(name);
    if (desc != null) {
      currentAnimation = name;
      current = desc;
      this.loop = desc.loop;
      if (desc.speed != null) this.speed = desc.speed;
      play(desc.frames, atFrame == null ? 0 : atFrame);
      wait = 0;
    }
  }
  
  /**
    Returns duration of specified animation. Uses either animation descriptor speed, or current Animation speed value.
  **/
  public function durationOf(anim:String):Float
  {
    var desc = animations.get(anim);
    if (frames != null)
    {
      return Animation.getDuration(desc.frames) * (desc.speed != null ? desc.speed : speed);
    }
    return 0;
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
        var desc = animations.get(name);
        if (desc != null)
        {
          playAnim(name, frame);
        }
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
        return pause;
    }
    return false;
  }
  
}

/**
  An animation descriptor used for AnimationExt.
  Describes general information about animation.
**/
class AnimationDescriptor
{
  /**
    List of frames used in animation.
  **/
  public var frames:Array<AnimationFrame>;
  
  /**
    Should this animation loop?
  **/
  public var loop:Bool;
  /**
    If not null, will set Animation.speed value to this value.
    Note: Does not reset to old value when switches to another animation.
  **/
  public var speed:Null<Float>;
  /**
    If present, will switch to specified animation name when this animation end.
    In that case, it will not trigger next command from buffer.
  **/
  public var next:String;
  /**
    Optional frame at which next animation should start.
  **/
  public var nextFrame:Null<Int> = null;
  
  // TODO: Buffer append
  // TODO: Event
  
  /**
    Creates new animation descriptor with specified frames.
  **/
  public function new(frames:Array<AnimationFrame>)
  {
    this.frames = frames;
  }
  
}

/**
  Type of animation command for AnimationExt command buffer.
**/
enum AnimationCommand 
{
  /**
    Delays execution of next command by specified time in seconds.
  **/
  Delay(time:Float);
  /**
    Switches to an animation with specified name and plays it at specified frame.
    If frame value is `null` - animation frame will not reset when switching to same animation.
    Executes next command immediately if animation not found.
  **/
  SwitchTo(name:String, frame:Null<Int>);
  /**
    Jumps to specified frame in current animation.
  **/
  Jump(frame:Int);
  /**
    Pauses playback.
    Executes next command immediately.
  **/
  Pause;
  /**
    Resets animation. Equivalent to Jump(0).
  **/
  Reset;
  /**
    Sets animation looping flag.
    Executes next command immediately.
  **/
  SetLoop(loop:Bool);
  /**
    Sets animation speed value.
    Executes next command immediately.
  **/
  SetSpeed(speed:Float);
  /**
    Calls `onEvent` with specified event name.
    Executes next command immediately.
  **/
  Event(name:String);
  /**
    Executes a chain of command ignoring if it should trigger next command or delay it.
    Delay command does not have an effect on Chain execution, but sets the animation delay.
    Executes next command immediately if animation is paused.
  **/
  Chain(commands:Array<AnimationCommand>);
}