package h2d.ui;

import hxd.Event;
import h2d.Object;

/**
  A button design based on openfl.display.SimpleButton
**/
class SimpleButton extends Interactive
{
  
  var idle:Object;
  var hover:Object;
  var press:Object;
  var disabled:Object;
  
  private var pressed:Bool;
  public var enabled(default, set):Bool = true;
  
  public function new(w:Int, h:Int, idle:Object, hover:Object, press:Object, ?disabled:Object, ?parent:Object)
  {
    // TODO: Disabled
    super(w, h, parent);
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
      if (isOver())
      {
        idle.visible = false;
        press.visible = pressed;
        hover.visible = !pressed;
      }
      else 
      {
        idle.visible = true;
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
    switch(e.kind)
    {
      case EventKind.EOver, EventKind.EOut:
        updateState();
      case EPush:
        pressed = true;
        updateState();
      case ERelease, EReleaseOutside:
        pressed = false;
        updateState();
      default:
    }
    super.handleEvent(e);
  }
}