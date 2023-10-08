package cherry.soup;

import hxd.Key;
import h2d.Tile;
import imgui.ImGui;
import cherry.soup.ImGuiTools;

typedef IGTimeline = ImGuiTimeline;

private class TimelinleState {
  
  public var zoom: Float = 1;
  public var scale: Float;
  
  public var region: ImVec2; // Timeline available region space.
  public var sp: ImVec2; // Timeline drawlist start position.
  
  // TODO: Row labels as separate region of timeline.
  
  public var y:Float = 0; // Current row offset.
  public var lastHeight:Float; // The total height of the timeline last frame
  
  public var sx: Float; // scrollX
  public var dl: ImDrawList;
  
  public var duration: Float;
  public var position: hl.Ref<Float>;
  
  public var row: Int;
  public var rowMax: Int;
  
  public var drag: Float; // Start position of scrubber drag, in case game edits it.
  
  public var opts: TimelineOptions;
  
  public function new(opts: TimelineOptions) {
    this.lastHeight = opts.rowHeight;
    this.zoom = opts.defaultZoom;
  }
  
  public inline function setCursor(pos: Float, offset: Float = 0, yoffset: Float = 0) {
    IG.setCursorPos(ITC.vec2(pos * scale + offset + opts.paddingX, y + yoffset + opts.paddingY));
  }
  
  public inline function clamp(pos: Float, applySnapping = true) {
    return if (opts.clampPositions && pos < 0) 0;
    else if (opts.clampPositions && pos > duration) duration;
    else if (applySnapping && opts.snapSteps > 0) Math.fround(pos / opts.snapSteps) * opts.snapSteps;
    else pos;
  }
  
}

@:structInit
class TimelineOptions {
  /** Drag/resize step snapping **/
  public var snapSteps:Float = 0;
  public var snapScrubber = false;
  public var clampPositions = false;
  
  /** Amount of notches per second of timeline (at 1 zoom) **/
  public var notchesPerSecond = 10;
  /** The size of 1 second at 1 zoom. **/
  public var secondSize = 50;
  public var durationPadding = 0.5;
  public var defaultZoom: Float = 3;
  
  public var rowHeight: Float = 20;
  public var paddingX: Float = 5;
  public var paddingY: Float = 5;
  
  public var pointSize: Float = 16;
  
  public var caretColor = 0xff2d8ceb;
  public var selectionColor = 0xffffff00;
  
}

class ImGuiTimeline {
  
  static var timelineState:Map<Int, TimelinleState> = [];
  public static var defaultTimelineOptions: TimelineOptions = {};
  
  inline static function pt(x: Float, y: Float) return ITC.vec2(x, y);
  
  static inline var TIMELINE_ID: String = "timeline";
  
  static inline function format(time: Float) return Math.round(time*100)/100 + "s";
  
  public static function begin(id: String, duration: Float, position: hl.Ref<Float>, ?options: TimelineOptions) {
    var regionMax = IG.getWindowContentRegionMax();
    if (options == null) options = defaultTimelineOptions;
    IG.pushStyleVar2(ImGuiStyleVar.WindowPadding, pt(0, 0));
    IG.beginChild("timeline##" + id, null, true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.HorizontalScrollbar | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoScrollWithMouse);
    IG.popStyleVar();
    var id = IG.getID(TIMELINE_ID);
    var state = timelineState[id];
    if (state == null) {
      timelineState[id] = state = new TimelinleState(options);
    }
    state.region = regionMax;
    state.scale = state.zoom * options.secondSize; //state.zoom * ((regionMax.x - options.paddingX*2) / duration);
    state.duration = duration;
    state.position = position;
    state.y = 0;
    state.sx = IG.getScrollX();
    state.dl = IG.getWindowDrawList();
    state.row = -1;
    state.rowMax = -1;
    state.opts = options;
    
    IG.setCursorPos(pt(0,0));
    state.sp = IG.getCursorScreenPos();
    state.sp.x += options.paddingX;
    state.sp.y += options.paddingY;
    regionMax.x -= options.paddingX*2;
    regionMax.y -= options.paddingY*2;
    
    IG.dummy(pt((duration+options.durationPadding) * state.scale + options.paddingX*2, options.rowHeight + options.paddingY));
    // var mm = IG.getWindowContentRegionMax();
    // IG.dummy(pt(regionMax.x * state.zoom + options.paddingX.x*2, timelineRowHeight + timelinePadding.y*2));
    // var exitPos = IG.getCursorPos();
    // IG.setCursorPos(point.set(0,0));
    
    var sx = state.sx;
    var dl = state.dl;
    dl.addRectFilled(pt(state.sp.x, options.rowHeight - 4 + state.sp.y), pt(state.sp.x + duration * state.scale, options.rowHeight + state.sp.y), 0xaa795a0e);
    
    // Draw timeline notches
    // TODO: Make them stick to top regardless of vsccroll
    var timePerNotch = 1 / options.notchesPerSecond;
    var notchStep = timePerNotch * state.scale;
    var h = state.lastHeight - 1;
    var notchMin = Math.floor(sx / notchStep);
    var notchMax = notchMin + Math.ceil(regionMax.x / notchStep);
    if (notchMin < 0) notchMin = 0;
    if (notchMax < notchMin) notchMax = notchMin+1;
    // dl.addText(pt(state.sp.x+20+state.sx, state.sp.y+80), 0xffffffff, '$notchStep, ${state.region.x}, ${state.sx}, ${notchMin} $notchMax');
    var minTextSize = IG.calcTextSize("00.00s");
    var textShowMod = Math.ceil((minTextSize.x+4)/notchStep);
    var notchMod = Math.ceil(8/notchStep);
    while (notchMin <= notchMax) {
      var x = notchMin * notchStep + state.sp.x;
      var time = notchMin * timePerNotch;
      // if ((notchMin % notchMod) == 0) 
      dl.addLine(pt(x, state.sp.y - 0.5), pt(x, state.sp.y + h), IG.getColorU32(Border), (notchMin % options.notchesPerSecond) == 0 ? 2 : 1.0);
      var txt = format(time);
      if (minTextSize.x + 4 < notchStep || (notchMin % textShowMod) == 0) {
        dl.addText(pt(x + 4, state.sp.y), IG.getColorU32(Text), txt);
      }
      // break;
      notchMin++;
    }
    
    var edited = false;
    
    IG.setCursorPos(pt(0, 0));
    IG.invisibleButton("scrubber", pt(Math.max(duration * state.scale + options.paddingX*2, 1), options.paddingY + options.rowHeight));
    

    // Draw hover cursor
    if (IG.isItemHovered()) { // isWindowHovered()
      var fgdl = IG.getForegroundDrawList();
      var mx = IG.getMousePos().x - state.sp.x;
      fgdl.addLine(pt(state.sp.x + mx, state.sp.y), pt(state.sp.x + mx, state.sp.y + state.lastHeight), (state.opts.caretColor & 0xffffff)|0x88000000);
      var text = format(mx / state.scale);
      var w = IG.calcTextSize(text).x + 4;
      if (mx - w <= 0) w = 10;
      else w = -w;
      fgdl.addText(pt(state.sp.x + mx + w, IG.getMousePos().y + 10), IG.getColorU32(Text, 1), text);
    }
    
    
    if (IG.isItemActivated()) state.drag = (IG.getMousePos().x - state.sp.x + sx) / state.scale;
    if (IG.isItemActive()) {
      var pos = state.drag + IG.getMouseDragDelta(0, 0).x / state.scale;
      pos = state.clamp(pos, options.snapScrubber && !Key.isDown(Key.SHIFT));
      position.set(pos);
      edited = true;
      
      var text = format(pos);
      var w = IG.calcTextSize(text).x + 4;
      if (pos*state.scale - w <= 0) w = 10;
      else w = -w;
      dl.addText(pt(state.sp.x + pos*state.scale + w, IG.getMousePos().y + 10), IG.getColorU32(Text, 1), text);
    } else if (IG.isWindowHovered()) {
      if (Key.isDown(Key.SHIFT)) {
        if (Key.isPressed(Key.MOUSE_WHEEL_DOWN)) {
          IG.setScrollX(state.sx + notchStep * 4);
        }
        if (Key.isPressed(Key.MOUSE_WHEEL_UP)) {
          IG.setScrollX(state.sx - notchStep * 4);
        }
      } else if (Key.isDown(Key.CTRL)) {
        if (Key.isPressed(Key.MOUSE_WHEEL_DOWN)) {
          state.zoom -= 0.2;
          if (state.zoom < 1) state.zoom = 1;
        }
        if (Key.isPressed(Key.MOUSE_WHEEL_UP)) {
          state.zoom += 0.2;
          if (state.zoom > 100) state.zoom = 100;
        }
      } else {
        if (Key.isPressed(Key.MOUSE_WHEEL_DOWN)) {
          IG.setScrollY(IG.getScrollY() + options.rowHeight);
        }
        if (Key.isPressed(Key.MOUSE_WHEEL_UP)) {
          IG.setScrollY(IG.getScrollY() - options.rowHeight);
        }
      }
      // TODO: Expose setting item edited and other flags.
    }
    return edited;
  }
  
  public static function row(?label: String) {
    var state = getState();
    setRow(state.row+1, label);
  }
  
  public static function setRow(row: Int, ?label: String) {
    var state = getState();
    state.row = row;
    var y = state.opts.rowHeight * (row+1);
    state.y = y;
    
    if (row > state.rowMax) {
      state.rowMax = row;
      y += state.sp.y;
      var dl = state.dl;
      dl.addLine(
        pt(state.sp.x - state.opts.paddingX + state.sx, y),
        pt(state.sp.x + state.region.x + state.opts.paddingX + state.sx, y),
        IG.getColorU32(ImGuiCol.Border, 0.3)
      );
      if (label != null) {
        var size = IG.calcTextSize(label);
        dl.addText(pt(state.sp.x + 5 + state.sx, state.sp.y + state.y + (state.opts.rowHeight - size.y) * .5), IG.getColorU32(Text, 0.5), label);
      }
    }
  }
  
  public static function range(label: String, start: hl.Ref<Float>, end: hl.Ref<Float>, color: Int, textColor:Int = 0xffffffff, minDuration: Float = 0.2, selected: Bool = false) {
    var state = getState();
    var ps = start.get();
    var pe = end.get();
    var left = Math.min(ps, pe);
    var right = Math.max(ps, pe);
    
    var edited = false;
    if (_point(state, label+"##start", start, false, ResizeEW, false)) edited = true;
    if (_point(state, label+"##end", end, false, ResizeEW, false)) edited = true;
    state.setCursor(left, state.opts.pointSize*.5);
    IG.invisibleButton(label, pt(Math.max(1, (right - left) * state.scale - state.opts.pointSize), state.opts.rowHeight));
    IG.setItemAllowOverlap();
    // state.dl.addText(IG.point.set(state.sp.x, state.sp.y+30), 0xffffffff, "" + (right - left - state.opts.pointSize));
    var ttip = IG.isItemHovered();
    if (IG.isItemActivated()) {
      var st = IG.getStateStorage();
      st.setFloat(IG.getID(label + "##range_drag_s"), ps);
      st.setFloat(IG.getID(label + "##range_drag_e"), pe);
    }
    if (IG.isItemActive()) {
      var dx = IG.getMouseDragDelta().x;
      if (dx != 0) {
        dx /=  state.scale;
        ps = state.clamp(IG.getStateStorage().getFloat(IG.getID(label + "##range_drag_s"), ps) + dx, !Key.isDown(Key.SHIFT));
        pe = state.clamp(IG.getStateStorage().getFloat(IG.getID(label + "##range_drag_e"), pe) + dx, !Key.isDown(Key.SHIFT));
        start.set(ps);
        end.set(pe);
        // TODO: Make it less janky
        // IG.resetMouseDragDelta();
        edited = true;
      }
      ttip = true;
    }
    if (ttip) {
      IG.setMouseCursor(Hand);
      IG.setTooltip(unhash(label) + " [" + format(left) + ", " + format(right) + "] -> " + format(right - left) + "");
    }
    var pt0 = pt(left*state.scale+state.sp.x, state.sp.y+state.y);
    var pt1 = pt(right*state.scale+state.sp.x, state.sp.y+state.y+state.opts.rowHeight);
    var dl = state.dl;
    dl.addRectFilled(
      pt0,
      pt1,
      color
    );
    pt1.y = state.sp.y + state.y + 2;
    dl.addRectFilled(pt0, pt1, 0x22ffffff);
    pt1.y = state.sp.y + state.y + state.opts.rowHeight;
    pt0.y = pt1.y - 2;
    dl.addRectFilled(pt0, pt1, 0x22000000);
    if (selected) {
      dl.addRect(
        pt(left*state.scale+state.sp.x, state.sp.y+state.y),
        pt(right*state.scale+state.sp.x, state.sp.y+state.y+state.opts.rowHeight),
        state.opts.selectionColor
      );
    }
    var size = IG.calcTextSize(label, null, true);
    dl.addText(pt(left * state.scale + state.sp.x + 4, state.sp.y + state.y + (state.opts.rowHeight - size.y) * .5), textColor, unhash(label));
    
    // IG.setCursorPos(pt(ps * state.scale - timelineRowHeight*.5 + timelinePadding.x, state.height));
    // IG.invisibleButton(label + "##start", pt(timelineRowHeight, timelineRowHeight));
    // if (IG.isItemHovered()) {
    //   IG.setMouseCursor(ImGuiMouseCursor.ResizeEW);
    //   ttip = true;
    // }
    // if (IG.isItemActive()) {
    //   IG.setMouseCursor(ImGuiMouseCursor.ResizeEW);
    //   var delta = IG.getMouseDragDelta().v.x;
    //   if (delta != 0) {
    //     ps += delta / state.scale;
    //     if (ps < 0) ps = 0;
    //     if (ps > state.duration) ps = state.duration;
    //     IG.resetMouseDragDelta();
    //     start.set(ps);
    //     edited = true;
    //   }
    //   ttip = true;
    // }
    // IG.setCursorPos(point.set(pe * state.scale - timelineRowHeight*.5 + timelinePadding.x, state.height));
    // IG.invisibleButton(label + "##end", point.set(timelineRowHeight, timelineRowHeight));
    // if (IG.isItemHovered()) {
    //   IG.setMouseCursor(ImGuiMouseCursor.ResizeEW);
    //   ttip = true;
    // }
    // if (IG.isItemActive()) {
    //   IG.setMouseCursor(ImGuiMouseCursor.ResizeEW);
    //   var delta = IG.getMouseDragDelta().v.x;
    //   if (delta != 0) {
    //     pe += delta / state.scale;
    //     if (pe < 0) pe = 0;
    //     if (pe > state.duration) pe = state.duration;
    //     IG.resetMouseDragDelta();
    //     end.set(pe);
    //     edited = true;
    //   }
    //   ttip = true;
    // }
    
    // IG.setCursorPos(point.set(left * state.scale + timelinePadding.x, state.height));
    // IG.invisibleButton(label+"##center", point.set((right - left) * state.scale, timelineRowHeight));
    // if (IG.isItemHovered()) {
    //   IG.setMouseCursor(ImGuiMouseCursor.Hand);
    //   ttip = true;
    // }
    // if (IG.isItemActive()) {
    //   IG.setMouseCursor(ImGuiMouseCursor.Hand);
    //   var delta = IG.getMouseDragDelta().v.x;
    //   if (delta != 0) {
    //     ps += delta / state.scale;
    //     if (ps < 0) ps = 0;
    //     if (ps > state.duration) ps = state.duration;
    //     pe += delta / state.scale;
    //     // TODO: Min-duration
    //     if (pe < 0) pe = 0;
    //     if (pe > state.duration) pe = state.duration;
    //     IG.resetMouseDragDelta();
    //     start.set(ps);
    //     end.set(pe);
    //     edited = true;
    //   }
    //   ttip = true;
    // }
    // var dl = IG.getWindowDrawList();
    // var size = IG.calcTextSize(label, null, true).v;
    // if (size.x + left * state.scale + timelinePadding.x*2 + timelineRowHeight - IG.getScrollX() >= state.region.x) size.x = -size.x - timelineRowHeight;
    // else size.x = timelineRowHeight;
    // dl.addRectFilled(point.set(left * state.scale + state.sp.x, state.height + state.sp.y), point2.set(right * state.scale + state.sp.x, state.height + state.sp.y + timelineRowHeight), color);
    // dl.addText(point.set(state.sp.x + left * state.scale + size.x, state.sp.y + state.height + (timelineRowHeight - size.y) * .5), textColor, label);
    
    // if (ttip) {
    //   IG.setTooltip(label + " (" + Math.floor((right - left) * 1000) + "ms)");
    // }
    return edited;
  }
  
  static function _point(state:TimelinleState, label: String, position: hl.Ref<Float>, sideLabel: Bool, cursor: ImGuiMouseCursor = Hand, tooltipOnhover = true) {
    // var state = getState();
    var pos = position.get();
    
    
    state.setCursor(pos, state.opts.pointSize*-.5);
    IG.invisibleButton(label, pt(Math.max(state.opts.pointSize, 1), state.opts.rowHeight));
    IG.setItemAllowOverlap();
    var edited = false;
    var ttip = tooltipOnhover && IG.isItemHovered();
    
    if (IG.isItemActivated()) IG.getStateStorage().setFloat(IG.getID(label + "##point_drag"), pos);
    if (IG.isItemActive()) {
      var dx = IG.getMouseDragDelta().x;
      if (dx != 0) {
        // pos += delta / state.scale;
        pos = IG.getStateStorage().getFloat(IG.getID(label + "##point_drag"), pos) + dx / state.scale;
        pos = state.clamp(pos, !Key.isDown(Key.SHIFT));
        // IG.resetMouseDragDelta();
        position.set(pos);
        edited = true;
      }
      ttip = true;
    }
    if (ttip) {
      IG.setMouseCursor(cursor);
      IG.setTooltip(unhash(label) + " [" + format(pos) + "]" );
    } else if (IG.isItemHovered()) IG.setMouseCursor(cursor);
    
    if (sideLabel) {
      var size = IG.calcTextSize(label, null, true);
      if (size.x +4 + state.opts.pointSize*.5 + pos * state.scale - state.sx >= state.region.x) size.x = -size.x - 4 - state.opts.pointSize*.5;
      else size.x = 4 + state.opts.pointSize*.5;
      state.dl.addText(pt(state.sp.x + pos*state.scale + size.x, state.sp.y + state.y + (state.opts.rowHeight - size.y) * .5), IG.getColorU32(Text), unhash(label));
    }
    return edited;
  }
  
  public static function point(label: String, position: hl.Ref<Float>, sideLabel = false, selected = false) {
    var state = getState();
    var pos = position.get();
    var edited = _point(state, label, position, sideLabel);
    var dl = state.dl;
    var col = if (IG.isItemActive()) IG.getColorU32(ButtonActive, 2);
      else if (IG.isItemHovered()) IG.getColorU32(ButtonHovered, 2);
      else IG.getColorU32(Button, 2);
    var pt0 = pt(pos*state.scale + state.sp.x, state.sp.y + state.y + state.opts.rowHeight * .5);
    dl.addCircleFilled(pt0, state.opts.pointSize*.5, col);
    if (selected) dl.addCircle(pt0, state.opts.pointSize*.5, state.opts.selectionColor);
    
    // if (icon != null) {
    //   var scale = Math.min(timelineRowHeight / icon.width,timelineRowHeight / icon.height);
    //   var ox = (icon.width * scale * .5);
    //   var oy = (icon.height * scale * .5);
    //   var x = pos * state.scale + state.sp.x;
    //   var y = state.sp.y + state.height + timelineRowHeight * .5;
    //   dl.addTile(icon, point.set(x-ox, y-oy), point2.set(x+ox, y+oy), color);
    // } else if (iconText != null) {
    //   dl.addText(point.set(pos * state.scale + state.sp.x, state.sp.y + state.height), color, iconText);
    // } else {
    //   dl.addCircleFilled(point.set(pos * state.scale + state.sp.x, state.sp.y + state.height + timelineRowHeight * .5), timelineRowHeight * .5, color);
    // }
    return edited;
  }
  
  public static function iconPoint(icon: String, label: String, position: hl.Ref<Float>, col: Int, sideLabel = false, selected = false) {
    var state = getState();
    var pos = position.get();
    var edited = _point(state, label, position, sideLabel);
    var dl = state.dl;
    if (selected) col = state.opts.selectionColor;
    var size = IG.calcTextSize(icon);
    dl.addText(pt(pos*state.scale + state.sp.x - size.x * .5, state.sp.y + state.y + (state.opts.rowHeight - size.y) * .5), col, icon);
    return edited;
  }
  
  // TODO: pointTile
  // TODO: pointText
  // TODO: pointWhatever
  
  public static function end() {
    var state = getState();
    state.lastHeight = (state.rowMax+2) * state.opts.rowHeight;
    
    var dl = state.dl;
    // Draw the scrubber
    var time = state.position.get() * state.scale;
    dl.addLine(pt(state.sp.x + time, state.sp.y), pt(state.sp.x + time, state.sp.y + state.lastHeight), state.opts.caretColor, 2);
    // IG.getWindowDrawList().addLine(pt(state.sp.x + time, state.sp.y), pt(state.sp.x + time, state.sp.y + state.lastHeight), 0xFFFFFFFF, 2.5 );
    
    IG.endChild();
  }
  
  static inline function unhash(label: String) {
    var idx = label.indexOf("##");
    return idx == -1 ? label : label.substr(0, idx);
  }
  
  static inline function getState() {
    var state = timelineState[IG.getID(TIMELINE_ID)];
    if (state == null) throw "Didn't call beginTimeline!";
    return state;
  }
}