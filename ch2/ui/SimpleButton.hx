package ch2.ui;

import hxd.Event;
import h2d.Object;
import h2d.col.Collider;

/**
  A simple button with simple premade 4 states.
  Based on openfl.display.SimpleButton design.
**/
class SimpleButton extends EventInteractive
{
  
  var idle:Object;
  var hover:Object;
  var press:Object;
  var disabled:Object;
  
  private var pressed:Bool;
  private var over:Bool;
  /**
    Button availability state. If `false`, does not Interact with mouse and showns `disabled` state.
  **/
  public var enabled(default, set):Bool = true;
  
  public function new(w:Int, h:Int, idle:Object, hover:Object, press:Object, ?disabled:Object, ?parent:Object, ?shape:Collider)
  {
    // TODO: Disabled
    super(w, h, parent, shape);
    this.idle = idle;
    addChild(idle);
    this.hover = hover;
    addChild(hover);
    this.press = press;
    addChild(press);
    if (disabled != null)
    {
      this.disabled = disabled;
      addChild(disabled);
    }
    else this.disabled = idle;
    
    updateState();
  }
  
  function set_enabled(v)
  {
    enabled = v;
    updateState();
    cursor = v ? Button : Default;
    return enabled;
  }
  
  function updateState()
  {
    if (enabled)
    {
      disabled.visible = false;
      if (over)
      {
        idle.visible = false;
        press.visible = pressed;
        hover.visible = !pressed;
      }
      else 
      {
        idle.visible = !pressed;
        press.visible = false;
        hover.visible = pressed;
      }
    }
    else 
    {
      idle.visible = false;
      press.visible = false;
      hover.visible = false;
      disabled.visible = true;
    }
  }
  
  override public function handleEvent(e:Event)
  {
    if (!enabled && checkBounds(e))
    {
      e.cancel = true;
      return;
    }
    super.handleEvent(e);
    if (!e.cancel)
    switch(e.kind)
    {
      case EventKind.EOver:
        over = true;
        updateState();
      case EventKind.EOut:
        over = false;
        updateState();
      case EPush:
        pressed = true;
        updateState();
      case ERelease, EReleaseOutside:
        pressed = false;
        updateState();
      default:
    }
  }
}