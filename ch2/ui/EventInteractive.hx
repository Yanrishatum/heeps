package ch2.ui;

import cherry.soup.EventSignal;
import hxd.Event;
import h2d.Interactive;

/**
  Simple wrapper to Interactive that allows multiple subscriptions to on* events.
  Overriding on* functions still possible.
**/
class EventInteractive extends Interactive
{
  
  public var onOverEvent:EventSignal1<Event> = new EventSignal1();
  public var onOutEvent:EventSignal1<Event> = new EventSignal1();
  public var onPushEvent:EventSignal1<Event> = new EventSignal1();
  public var onReleaseEvent:EventSignal1<Event> = new EventSignal1();
  public var onReleaseOutsideEvent:EventSignal1<Event> = new EventSignal1();
  public var onClickEvent:EventSignal1<Event> = new EventSignal1();
  public var onMoveEvent:EventSignal1<Event> = new EventSignal1();
  public var onWheelEvent:EventSignal1<Event> = new EventSignal1();
  public var onFocusEvent:EventSignal1<Event> = new EventSignal1();
  public var onFocusLostEvent:EventSignal1<Event> = new EventSignal1();
  public var onKeyUpEvent:EventSignal1<Event> = new EventSignal1();
  public var onKeyDownEvent:EventSignal1<Event> = new EventSignal1();
  public var onCheckEvent:EventSignal1<Event> = new EventSignal1();
  public var onTextInputEvent:EventSignal1<Event> = new EventSignal1();
  
  override public function handleEvent(e:Event)
  {
		if( parentMask != null && checkBounds(e) ) {
			var p = parentMask;
			var pt = new h2d.col.Point(e.relX, e.relY);
			localToGlobal(pt);
			var saveX = pt.x, saveY = pt.y;
			while( p != null ) {
				pt.x = saveX;
				pt.y = saveY;
				var pt = p.globalToLocal(pt);
				if( pt.x < 0 || pt.y < 0 || pt.x > p.width || pt.y > p.height ) {
					e.cancel = true;
					return;
				}
				p = @:privateAccess p.parentMask;
			}
		}
		if(shape == null && isEllipse && checkBounds(e) ) {
			var cx = width * 0.5, cy = height * 0.5;
			var dx = (e.relX - cx) / cx;
			var dy = (e.relY - cy) / cy;
			if( dx * dx + dy * dy > 1 ) {
				e.cancel = true;
				return;
			}
		}
		if( propagateEvents ) e.propagate = true;
		if( cancelEvents ) e.cancel = true;
		switch( e.kind ) {
		case EMove:
      onMoveEvent.dispatch(e);
			onMove(e);
		case EPush:
			if( enableRightButton || e.button == 0 ) {
				mouseDownButton = e.button;
        onPushEvent.dispatch(e);
				onPush(e);
			}
		case ERelease:
			if( enableRightButton || e.button == 0 ) {
        onReleaseEvent.dispatch(e);
				onRelease(e);
				if( mouseDownButton == e.button )
        {
          onClickEvent.dispatch(e);
					onClick(e);
        }
			}
			mouseDownButton = -1;
		case EReleaseOutside:
			if( enableRightButton || e.button == 0 ) {
        onReleaseEvent.dispatch(e);
				onRelease(e);
				if ( mouseDownButton == e.button )
        {
          onReleaseOutsideEvent.dispatch(e);
					onReleaseOutside(e);
        }
			}
			mouseDownButton = -1;
		case EOver:
      onOverEvent.dispatch(e);
			onOver(e);
			if( !e.cancel && cursor != null )
				hxd.System.setCursor(cursor);
		case EOut:
			mouseDownButton = -1;
      onOutEvent.dispatch(e);
			onOut(e);
			if( !e.cancel )
				hxd.System.setCursor(Default);
		case EWheel:
      onWheelEvent.dispatch(e);
			onWheel(e);
		case EFocusLost:
      onFocusLostEvent.dispatch(e);
			onFocusLost(e);
		case EFocus:
      onFocusEvent.dispatch(e);
			onFocus(e);
		case EKeyUp:
      onKeyUpEvent.dispatch(e);
			onKeyUp(e);
		case EKeyDown:
      onKeyDownEvent.dispatch(e);
			onKeyDown(e);
		case ECheck:
      onCheckEvent.dispatch(e);
			onCheck(e);
		case ETextInput:
      onTextInputEvent.dispatch(e);
			onTextInput(e);
		}
  }
}