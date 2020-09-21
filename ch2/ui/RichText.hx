package ch2.ui;

import ch2.ui.effects.RichTextEffect;
import h3d.shader.SignedDistanceField;
import h2d.col.Bounds;
import h2d.Drawable;

class RichText extends Drawable {
  
  public var defaultFormat(default, set):RichTextFormat;
  
  public var maxWidth(default, set):Null<Float>;
  var realMaxWidth:Float;
  var constraintWidth:Float = -1;
  
  var needReFinalize:Bool;
  
  var nodes:Array<RichTextNode>;
  var lines:Array<TextLine>;
  var lastLine:TextLine;
  // Break data
  var breakNodeIndex:Int;
  var breakIndex:Int;
  var breakWidth:Float;
  var breakBatchIndex:Int;
  
  var currentFormat:RichTextFormat;
  var content:Array<BatchDrawer> = [];
  var batch:BatchDrawer;
  
  var calcXMin:Float;
  var calcYMin:Float;
  var calcWidth:Float;
  var calcHeight:Float;
  var calcSizeHeight:Float;
  
  public function new(?format:RichTextFormat, ?orFont:Font, ?parent) {
    super(parent);
    if (format == null) {
      if (orFont == null) throw "Should provide either font or format!";
      defaultFormat = new RichTextFormat(orFont, 0xffffff, 1, Left, null, []);
    } else if (orFont != null) {
      throw "Should provide only format or font, not both!";
    } else {
      defaultFormat = format;
    }
    
    clear();
  }
  
  public function clear() {
    if (lines != null) {
      for (l in lines) for (n in l.nodes) for (e in n.format.effects) e.reset();
      for (c in content) c.remove();
    }
    lines = [];
    nodes = [];
    content = [];
    lastLine = null;
    currentFormat = null;
    needReFinalize = false;
    
    calcMaxWidth();
    calcXMin = 0;
    calcYMin = 0;
    calcWidth = 0;
    calcHeight = 0;
    calcSizeHeight = 0;
  }
  
  function finalizeLine(ll:TextLine, prev:TextLine) {
    ll.height = 0;
    ll.base = 0;
    ll.width = 0;
    ll.finalized = true;
    if (prev != null) {
      ll.y = prev.y + prev.height;
    } else {
      ll.y = 0;
    }
    for (n in ll.nodes) {
      var fnt = n.format.getFont(defaultFormat.font);
      ll.width += n.width;
      if (ll.base < fnt.baseLine) ll.base = fnt.baseLine;
      if (ll.height < fnt.lineHeight) ll.height = fnt.lineHeight;
    }
    
    var x = 0.;
    var y = ll.y;
    switch(ll.align) {
      case Left:
        x = 0;
      case Right:
        if (realMaxWidth == -1) x = -ll.width;
        else x = realMaxWidth - ll.width;
      case Center:
        if (realMaxWidth == -1) x = -Math.round(ll.width * .5);
        else x = Math.round((realMaxWidth - ll.width) / 2);
      case MultilineCenter: throw "Not supported";
      case MultilineRight: throw "Not supported";
    }
    
    if (x < calcXMin) calcXMin = x;
    if (y < calcYMin) calcYMin = y;
    if (ll.width > calcWidth) calcWidth = ll.width;
    if (y + ll.height > calcHeight) calcHeight = y + ll.height;
    if (y + ll.base > calcSizeHeight) calcSizeHeight = y + ll.base;
    
    var bounds = new Bounds();
    
    for (n in ll.nodes) {
      switch (n.node) {
        case NText(text, format):
          var fnt = format.getFont(defaultFormat.font);
          var charset = fnt.charset;
          var yoff = ll.base - fnt.baseLine;
          var prev = -1;
          var batch = n.batch;
          var idx = n.batchMin;
          for (i in n.min...n.max) {
            var code = text.charCodeAt(i);
            var char = fnt.getChar(code);
            if (char == null) {
              prev = code;
              continue;
            }
            if (charset.isSpace(code)) {
              x += char.width + char.getKerningOffset(prev);
              prev = code;
              continue;
            }
            var kern = char.getKerningOffset(prev);
            batch.setPos(idx++, x + char.getKerningOffset(prev) + char.t.dx, y + yoff + char.t.dy);
            prev = code;
            x += char.width + kern;
          }
        case NTile(t, advance, isBreak, format):
          n.batch.setPos(n.batchMin, x + t.dx, y + ll.base - t.height + t.dy);
          x += n.width;
        case NObject(o, advance, isBreak, format):
          var size = o.getSize(bounds);
          o.x = x;
          o.y = y + ll.base - size.height;
          x += n.width;
        case NLineBreak: throw "Line break nodes in lines";
      }
    }
    
    for (n in ll.nodes) {
      if (n.batchMin != n.batchMax) {
        for (e in n.format.effects) {
          e.init(n.batch, n.batchMin, n.batchMax, n);
        }
      }
    }
  }
  
  inline function ensureFinalized() {
    if (lastLine != null && !lastLine.finalized) finalizeLine(lastLine, lines.length > 1 ? lines[lines.length - 2] : null);
  }
  
  // TODO: Kerning chaining between nodes
  function newLine() {
    ensureFinalized();
    lastLine = new TextLine();
    if (lines.length != 0) {
      var prev = lines[lines.length - 1];
    }
    breakNodeIndex = -1;
    lines.push(lastLine);
    return lastLine;
  }
  
  function breakLine() {
    if (breakNodeIndex != -1) {
      var bni = breakNodeIndex;
      var ll = lastLine;
      var nl:TextLine;
      var nodeInfo = ll.nodes[bni++];
      var remainder = ll.nodes.splice(bni, ll.nodes.length);
      switch (nodeInfo.node) {
        case NText(text, format):
          var fnt = format.getFont(defaultFormat.font);
          var code = text.charCodeAt(breakIndex);
          var char = fnt.getChar(code);
          nodeInfo.max = breakIndex;
          var w = nodeInfo.width - breakWidth;
          nodeInfo.width = breakWidth;
          var batchmax = nodeInfo.batchMax;
          nodeInfo.batchMax = breakBatchIndex;
          nl = newLine();
          if (fnt.charset.isSpace(code)) {
            nl.add(nodeInfo.max + 1, text.length, breakBatchIndex, batchmax, w - char.width, nodeInfo.batch, format, nodeInfo.node);
          } else {
            nl.add(nodeInfo.max, text.length, breakBatchIndex, batchmax, w, nodeInfo.batch, format, nodeInfo.node);
          }
        case NTile(_, advance, isBreak, format), NObject(_, advance, isBreak, format):
          switch (isBreak) {
            case BLeft:
              ll.nodes.pop(); // remove tile
              nl = newLine();
              nl.nodes.push(nodeInfo);
              nl.width += advance;
            case BRight, BBoth:
              nl = newLine();
            case BNone: throw "Break pointer at non-break tile?";
          }
        case NLineBreak: throw "Can't have line-breaks in line nodes";
      }
      for (r in remainder) {
        nl.nodes.push(r);
        nl.width += r.width;
      }
    }
    return lastLine;
  }
  
  function validateAlign(format:RichTextFormat):Align {
    var align = format.getAlign(lastLine.align);
    if (align == null) align = defaultFormat.align;
    if (lastLine.align == null) lastLine.align = align;
    else if (lastLine.align != align) {
      // When changing align - force line-break.
      lastLine = newLine();
      lastLine.align = align;
    }
    return align;
  }
  
  function validateBatcher(format:RichTextFormat) {
    if (this.batch == null) {
      splitBatcher(format);
      return;
    }
    if (this.currentFormat == format) return; // No point
    if (currentFormat == null) {
      currentFormat = format;
      return;
    }
    // Check that we don't have new effect compposition
    // Probably could optimize by switching batches only on shader effects
    var newCount = 0;
    for (e in format.getEffects()) newCount++;
    var oldCount = 0;
    for (e in currentFormat.getEffects()) oldCount++;
    var changed = newCount != oldCount;
    
    if (!changed) {
      for (e in currentFormat.getEffects()) {
        var found = false;
        for (e2 in format.getEffects()) {
          if (e2 == e) {
            found = true;
            break;
          }
        }
        if (!found) {
          changed = true;
          break;
        }
      }
      if (!changed) {
        // Check if we have font changed
        // For bitmap fonts it's not required, but SDF fonts force switch.
        var font = format.getFont(defaultFormat.font);
        var oldFont = currentFormat.getFont(defaultFormat.font);
        if (font != oldFont) {
          changed = font.type != BitmapFont || oldFont.type != BitmapFont;
        }
      }
    }
    if (changed) {
      splitBatcher(format);
    }
  }
  
  function splitBatcher(format:RichTextFormat) {
    var b = new BatchDrawer(this);
    currentFormat = format;
    content.push(b);
    batch = b;
    batch.smooth = this.smooth;
    var font = format.getFont(defaultFormat.font);
    switch (font.type) {
      case BitmapFont: // Do nothing
      case SignedDistanceField(channel, alphaCutoff, smoothing):
        batch.smooth = true;
        var sdf = new SignedDistanceField();
        sdf.channel = channel;
        sdf.alphaCutoff = alphaCutoff;
        sdf.smoothing = smoothing;
        batch.addShader(sdf);
    }
    for (e in format.effects) e.attach(b);
  }
  
  public function addText(text:String, ?format:RichTextFormat) {
    if (lastLine == null) newLine();
    if (format == null) format = defaultFormat;
    
    validateBatcher(format);
    var align = validateAlign(format);
    var ll = lastLine;
    
    if (ll.align == null) ll.align = align;
    else if (ll.align != align) {
      // When changing align - force line-break.
      ll = newLine();
      ll.align = align;
    }
    
    final fnt = format.getFont(defaultFormat.font);
    final charset = fnt.charset;
    final len = text.length;
    
    var col = format.getColor(defaultFormat.color);
    var r = (col >> 16 & 0xff) / 0xff;
    var g = (col >> 8 & 0xff) / 0xff;
    var b = (col & 0xff) / 0xff;
    var a = format.getAlpha();
    
    var x = ll.width;
    var size = 0., chw;
    var prev = -1;
    var start = 0;
    var breakPos = -1;
    var breakChar:Int = 0;
    var lastBatchInsert = batch.counter;
    var breakCounter:Int = batch.counter;
    var i = 0;
    var node = NText(text, format);
    nodes.push(node);
    while (i < len) {
      var code = text.charCodeAt(i);
      if (code == '\n'.code) {
        ll.add(start, i, lastBatchInsert, batch.counter, x + size - ll.width, batch, format, node);
        ll = newLine();
        ll.align = align;
        lastBatchInsert = batch.counter;
        size = 0;
        x = 0;
        start = i + 1;
        breakPos = -1;
        prev = -1;
        i++;
        continue;
      }
      var char = fnt.getChar(code);
      if (char == null) {
        // non-printer
        prev = code;
        i++;
        continue;
      }
      chw = char.width + char.getKerningOffset(prev);
      
      if (realMaxWidth != -1) {
        var isBreak = charset.isBreakChar(code);
        if (isBreak) {
          breakPos = i;
          breakChar = code;
          breakCounter = batch.counter;
          x += size;
          size = 0;
        }
        
        if (x + size + chw >= realMaxWidth) {
          if (breakPos == -1) {
            x -= ll.width;
            ll = breakLine();
            x += ll.width;
          } else {
            // Do a line-break;
            ll.add(start, breakPos, lastBatchInsert, breakCounter, x - ll.width, batch, format, node);
            lastBatchInsert = breakCounter;
            start = breakPos;
            if (charset.isSpace(breakChar)) {
              start++; // Skip space
            }
            ll = newLine();
            x = 0;
            breakPos = -1;
          }
          ll.align = align;
        }
      }
      
      size += chw;
      i++;
      if (!charset.isSpace(code)) {
        batch.addColor(0, 0, r, g, b, a, char.t);
      }
      prev = code;
    }
    if (breakPos != -1) {
      breakNodeIndex = ll.nodes.length;
      breakIndex = breakPos;
      breakWidth = x;
      breakBatchIndex = batch.counter;
    }
    if (start != i) {
      ll.add(start, i, lastBatchInsert, batch.counter, x + size - ll.width, batch, format, node);
    }
  }
  
  public function addTile(t:Tile, ?advance:Float, ?isBreak:BreakRule, ?format:RichTextFormat) {
    if (lastLine == null) newLine();
    if (format == null) format = defaultFormat;
    
    validateBatcher(format);
    var align = validateAlign(format);
    var ll = lastLine;
    
    if (advance == null) advance = t.width - t.dx;
    if (isBreak == null) isBreak = BNone;
    
    if (realMaxWidth != -1 && ll.width + advance >= realMaxWidth) {
      if (isBreak == BBoth || isBreak == BLeft) {
        if (lines.length != 1 || ll.width == 0) ll = newLine();
      } else {
        ll = breakLine();
      }
      ll.align = align;
    }
    if (isBreak != BNone) {
      // Don't introduce break index when it's the first item in the line, and we break on the left.
      if (isBreak != BLeft || lastLine.nodes.length != 0) {
        breakNodeIndex = ll.nodes.length;
      }
    }
    var node = NTile(t, advance, isBreak, format);
    nodes.push(node);
    ll.add(0, 1, batch.counter, batch.counter + 1, advance, batch, format, node);
    batch.add(0, 0, t); // Positioned later
  }
  
  public function addObject(o:Object, ?advance:Float, ?isBreak:BreakRule, ?format:RichTextFormat) {
    if (lastLine == null) newLine();
    if (format == null) format = defaultFormat;
    
    var align = validateAlign(format);
    var ll = lastLine;
    
    var size = o.getSize();
    if (advance == null) advance = size.width;
    if (isBreak == null) isBreak = BNone;
    
    if (realMaxWidth != -1 && ll.width + advance >= realMaxWidth) {
      if (isBreak == BBoth || isBreak == BLeft) {
        if (lines.length != 1 || ll.width == 0) ll = newLine();
      } else {
        ll = breakLine();
      }
      ll.align = align;
    }
    addChild(o);
    if (isBreak != BNone) {
      // Don't introduce break index when it's the first item in the line, and we break on the left.
      if (isBreak != BLeft || ll.nodes.length != 0) {
        breakNodeIndex = ll.nodes.length;
      }
    }
    var node = NObject(o, advance, isBreak, format);
    nodes.push(node);
    ll.add(0, 0, 0, 0, advance, null, format, node);
  }
  
  public function addLineBreak() {
    if (lastLine == null) newLine(); // Insert empty line at start.
    ensureFinalized();
    lastLine = null;
    nodes.push(NLineBreak);
  }
  
  public function addNode(node:RichTextNode) {
    switch (node) {
      case NText(text, format):
        addText(text, format);
      case NTile(t, advance, isBreak, format):
        addTile(t, advance, isBreak, format);
      case NObject(o, advance, isBreak, format):
        addObject(o, advance, isBreak, format);
      case NLineBreak:
        addLineBreak();
    }
  }
  
  override function sync(ctx:RenderContext)
  {
    if (needReFinalize) {
      var old = nodes;
      clear();
      for (n in nodes) addNode(n);
    }
    ensureFinalized();
    for (l in lines) {
      for (n in l.nodes) {
        for (e in n.format.effects) {
          if (e.frame != ctx.frame) {
            e.frame = ctx.frame;
            e.begin(batch, ctx);
          }
          e.sync(batch, ctx, n.batchMin, n.batchMax, n);
        }
      }
    }
    super.sync(ctx);
  }
  
  override function getBoundsRec( relativeTo : Object, out : Bounds, forSize : Bool ) {
    super.getBoundsRec(relativeTo, out, forSize);
    ensureFinalized();
    var x, y, w : Float, h;
    if ( forSize ) {
      x = calcXMin;  // TODO: Should be 0 as well for consistency, but currently causes problems with Flows
      y = 0.;
      w = calcWidth;
      h = calcSizeHeight;
    } else {
      x = calcXMin;
      y = calcYMin;
      w = calcWidth;
      h = calcHeight - calcYMin;
    }
    addBounds(relativeTo, out, x, y, w, h);
  }

  function set_defaultFormat(format:RichTextFormat):RichTextFormat {
    if (format == null) throw "Can't have null default format!";
    if (format.font == null) throw "Format should have a font!";
    if (format.color == null) format.color = 0xffffff;
    if (format.align == null) format.align = Left;
    return defaultFormat = format;
  }
  
  function calcMaxWidth() {
    var old = realMaxWidth;
    if( maxWidth == null )
      realMaxWidth = constraintWidth;
    else if( constraintWidth < 0 )
      realMaxWidth = maxWidth;
    else
      realMaxWidth = hxd.Math.min(maxWidth, constraintWidth);
    if( realMaxWidth != old && lines.length > 0) needReFinalize = true;
  }
  
  override function constraintSize(maxWidth:Float, maxHeight:Float) {
    constraintWidth = maxWidth;
    calcMaxWidth();
  }
  
  public function set_maxWidth(v:Null<Float>):Null<Float> {
    maxWidth = v;
    calcMaxWidth();
    return v;
  }

}

// Public data

enum RichTextNode {
  NText(text:String, ?format:RichTextFormat);
  NTile(t:Tile, ?advance:Float, ?isBreak:BreakRule, ?format:RichTextFormat);
  NObject(o:Object, ?advance:Float, ?isBreak:BreakRule, ?format:RichTextFormat);
  NLineBreak;
}

enum BreakRule {
  BLeft;
  BRight;
  BBoth;
  BNone;
}

class RichTextFormat {
  public var font:Font;
  public var color:Null<Int>;
  public var alpha:Float;
  public var align:Align;
  public var parent:RichTextFormat;
  public var effects:Array<RichTextEffect>;
  
  public function new(?font:Font, ?color:Int, alpha:Float = 1, ?align:Align, ?parent:RichTextFormat, ?effects:Array<RichTextEffect>) {
    this.font = font;
    this.color = color;
    this.alpha = alpha;
    this.align = align;
    this.parent = parent;
    this.effects = effects == null ? [] : effects;
  }
  
  public function getFont(fallback:Font):Font {
    if (font != null) return font;
    var p = parent;
    while (p != null) {
      if (p.font != null) return p.font;
      p = p.parent;
    }
    return fallback;
  }
  
  public function getColor(fallback:Int):Int {
    if (color != null) return color;
    var p = parent;
    while (p != null) {
      if (p.color != null) return p.color;
      p = p.parent;
    }
    return fallback;
  }
  
  public function getAlpha():Float {
    var a = this.alpha;
    var p = parent;
    while (p != null) {
      a *= p.alpha;
      p = p.parent;
    }
    return a;
  }
  
  public function getAlign(fallback:Align):Align {
    if (align != null) return align;
    var p = parent;
    while (p != null) {
      if (p.align != null) return p.align;
      p = p.parent;
    }
    return fallback;
  }
  
  public function getEffects():Iterator<RichTextEffect> {
    return new EffectsIterator(this);
  }
  
}

private class EffectsIterator {
  var cur:RichTextFormat;
  var pos:Int;
  
  public inline function new(cur:RichTextFormat) {
    this.cur = cur.effects.length == 0 ? null : cur;
    this.pos = 0;
  }
  
  public inline function hasNext():Bool {
    return cur != null;
  }
  
  public inline function next():RichTextEffect {
    var eff = cur.effects[pos++];
    if (pos == cur.effects.length) cur = cur.parent;
    return eff;
  }
  
}

// Entry controls

class TextLine {
  
  public var nodes:Array<NodeRange> = [];
  
  public var y:Float = 0;
  public var width:Float = 0;
  public var height:Float = 0;
  public var base:Float = 0;
  public var align:Align;
  public var finalized:Bool = false;
  
  public function new() {}
  
  public inline function add(min:Int, max:Int, bmin:Int, bmax:Int, width:Float, batch:BatchDrawer, format:RichTextFormat, node:RichTextNode) {
    nodes.push({ min: min, max: max, batchMin: bmin, batchMax: bmax, width: width, format: format, node: node, batch: batch });
    this.width += width;
    finalized = false;
  }
  
}

typedef NodeRange = {
  var min:Int;
  var max:Int;
  var batchMin:Int;
  var batchMax:Int;
  var width:Float;
  var batch:BatchDrawer;
  
  var format:RichTextFormat;
  var node:RichTextNode;
}
