package hxd.heeps;

@:structInit
private class SignalListener<T:haxe.Constraints.Function>
{
  
  public var listener:T;
  public var priority:Int;
  public var once:Bool;
  
}

class EventSignal<T:haxe.Constraints.Function>
{
  
  public var cancelled:Bool;
  var listeners:Array<SignalListener<T>>;
  var dirty:Bool;
  
  public function new()
  {
    listeners = new Array();
  }
  
  public function cancel():Void
  {
    cancelled = true;
  }
  
  public function add(listener:T, priority:Int = 0, once:Bool = false):Void
  {
    listeners.push({
      listener: listener,
      priority: priority,
      once: once
    });
    dirty = true;
  }
  
  public function remove(listener:T):Bool
  {
    for (l in listeners)
    {
      if (Reflect.compareMethods(listener, l.listener))
      {
        listeners.remove(l);
        return true;
      }
    }
    return false;
  }
  
  function listenerSort(a:SignalListener<T>, b:SignalListener<T>):Int
  {
    if (a.priority < b.priority) return 1;
    else return a.priority == b.priority ? 0 : -1;
  }
  inline function reset():Void
  {
    cancelled = false;
    if (dirty)
    {
      dirty = false;
      listeners.sort(listenerSort);
    }
  }
  
}

class EventSignal0 extends EventSignal<Void->Void>
{
  
  public function dispatch():Bool
  {
    reset();
    var rem:Array<SignalListener<Void->Void>> = new Array();
    for (l in listeners)
    {
      l.listener();
      if (l.once) rem.push(l);
      if (cancelled) break;
    }
    for (e in rem) listeners.remove(e);
    return !cancelled;
  }
  
}

class EventSignal1<T> extends EventSignal<T->Void>
{
  public function dispatch(arg:T):Bool
  {
    reset();
    var rem:Array<SignalListener<T->Void>> = new Array();
    for (l in listeners)
    {
      l.listener(arg);
      if (l.once) rem.push(l);
      if (cancelled) break;
    }
    for (e in rem) listeners.remove(e);
    return !cancelled;
  }
}

class EventSignal2<A0, A1> extends EventSignal<A0->A1->Void>
{
  public function dispatch(arg0:A0, arg1:A1):Bool
  {
    reset();
    var rem:Array<SignalListener<A0->A1->Void>> = new Array();
    for (l in listeners)
    {
      l.listener(arg0, arg1);
      if (l.once) rem.push(l);
      if (cancelled) break;
    }
    for (e in rem) listeners.remove(e);
    return !cancelled;
  }
}

class EventSignal3<A0, A1, A2> extends EventSignal<A0->A1->A2->Void>
{
  public function dispatch(arg0:A0, arg1:A1, arg2:A2):Bool
  {
    reset();
    var rem:Array<SignalListener<A0->A1->A2->Void>> = new Array();
    for (l in listeners)
    {
      l.listener(arg0, arg1, arg2);
      if (l.once) rem.push(l);
      if (cancelled) break;
    }
    for (e in rem) listeners.remove(e);
    return !cancelled;
  }
}

class EventSignal4<A0, A1, A2, A3> extends EventSignal<A0->A1->A2->A3->Void>
{
  public function dispatch(arg0:A0, arg1:A1, arg2:A2, arg3:A3):Bool
  {
    reset();
    var rem:Array<SignalListener<A0->A1->A2->A3->Void>> = new Array();
    for (l in listeners)
    {
      l.listener(arg0, arg1, arg2, arg3);
      if (l.once) rem.push(l);
      if (cancelled) break;
    }
    for (e in rem) listeners.remove(e);
    return !cancelled;
  }
}