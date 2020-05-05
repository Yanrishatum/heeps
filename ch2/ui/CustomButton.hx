package ch2.ui;

import h2d.Object;
import h2d.col.Collider;

/**
  When regular Interactive is too little, but SimpleButton is too inflexible. Write your own state view!
  Class handles keeping track of current button state as well as lets you simulate the state.
  More specific behavior can be achieved by using flags.
  All View have to do is implement `setState(state, flags)` method and handle viewing specific state.
**/
class CustomButton extends EventInteractive
{
  public var views:Array<IButtonStateView>;
  
  /**
    Current state of the button in regard to mouse interaction.
  **/
  public var flags(default, null):ButtonFlags;
  /**
    Flag list the button currently contains. Does not affect state invalidation and used solely for views to utilize.  
    Most simple use-case is disabling the button.
  **/
  public var state(default, null):ButtonState;
  
  /**
    Current simulated state. Disabled if set to 0xff.
    While simulated state is active, CustomButton keeps track of real button state, but does not invalidate the view.
  **/
  public var simState(default, null):ButtonState = 0xff;
  
  public function new(width:Float, height:Float, ?parent:Object, ?shape:Collider, ?views:Array<IButtonStateView>)
  {
    super(width, height, parent, shape);
    flags = None;
    state = Idle;
    this.views = views != null ? views : [];
    for (v in views) {
      // if (Std.is(v, Object) && cast (v:Object) != this) {
      //   addChild(cast v);
      // }
      v.setState(state, flags);
    }
    onOverEvent.add(setStateOver);
    onOutEvent.add(setStateOut);
    onPushEvent.add(setStatePress);
    onReleaseEvent.add(setStateUnpress);
  }
  
  override public function addChildAt(s:Object, pos:Int)
  {
    super.addChildAt(s, pos);
    if (Std.is(s, IButtonStateView)) {
      var v:IButtonStateView = cast s;
      if (views.indexOf(v) == -1) views.push(v);
    }
  }
  
  function setStateOver(_) updateState(state == Hold ? Press : Hover);
  function setStateOut(_) updateState(state == Press ? Hold : Idle);
  function setStatePress(e:hxd.Event) {
    if (e.button == 0) flags.set(LeftButtonPress);
    else flags.set(RightButtonPress);
    updateState(state == Hover ? Press : Hold);
  }
  function setStateUnpress(e:hxd.Event) {
    if (e.button == 0) flags.reset(LeftButtonPress);
    else flags.reset(RightButtonPress);
    updateState(state == Press ? Hover : Idle);
  }
  
  inline function updateState(to:ButtonState) {
    state = to;
    if (simState == 0xff) invalidate();
  }
  
  public function setFlag(flag:ButtonFlags, value:Bool)
  {
    flags = (value ? flags.set(flag) : flags.reset(flag));
    invalidate();
  }
  
  public inline function simulateState(state:ButtonState)
  {
    simState = state;
    invalidate();
  }
  
  public inline function clearSimulatedState()
  {
    simState = 0xff;
    invalidate();
  }
  
  /** Invalidates button and forces invalidate to be called. **/
  public function invalidate()
  {
    var s = simState == 0xff ? state : simState;
    for (v in views) v.setState(s, flags);
  }
  
}

// class ButtonState extends AnimationExt
// {
  
//   public static function 
  
// }

interface IButtonStateView {
  
  function setState(state:ButtonState, flags:ButtonFlags):Void;
  
}

enum abstract ButtonFlags(Int) {
  
  var None = 0;
  var Toggled = 1;
  var Disabled = 2;
  var Focused = 4;
  var Clicked = 8;
  var Error = 16;
  var Success = 32;
  var LeftButtonPress = 64;
  var RightButtonPress = 128;
  var Custom1 = 256;
  var Custom2 = 512;
  var Custom3 = 1024;
  var Custom4 = 2048;
  
  public inline function has(flag:ButtonFlags):Bool {
    return (this & flag.toInt()) == flag.toInt();
  }
  
  public inline function set(flag:ButtonFlags):ButtonFlags {
    return asFlag(this | flag.toInt());
  }
  
  public inline function reset(flag:ButtonFlags):ButtonFlags {
    return asFlag(this & ~flag.toInt());
  }
  
  public static inline function asFlag(i:Int):ButtonFlags return cast(i);
  public inline function toInt():Int return this;
  
}

enum abstract ButtonState(Int) to Int from Int {
  
  // Unpressed
  var Idle = 0;
  // Mouse over
  var Hover = 1;
  // Pressed
  var Press = 3;
  // Pressed, not hovered
  var Hold = 2;
  
}