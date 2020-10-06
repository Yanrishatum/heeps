package ch2.ui.effects;

import hxd.FloatBuffer;
import ch2.ui.RichText;
import ch2.BatchDrawer;
import h2d.RenderContext;

class RichTextEffect {
  
  public var once:Bool = false;
  public var active:Bool = true;
  public var frame:Int;
  public var endFrame:Int;
  
  public function new() {
    
  }
  
  public function reset() {
    
  }
  
  public function attach(content:RichTextRenderer) {
    // When batcher with that compo is made.
  }
  
  public function init(content:RichTextContent, start:Int, end:Int, node:NodeRange) {
    // On finalize
  }
  
  /**
    Called every frame before sync
  **/
  public function begin(ctx:RenderContext) {
    // Before sync
  }
  
  /** Return false when done. **/
  public function sync(content:RichTextContent, ctx:RenderContext, start:Int, end:Int, node:NodeRange):Bool {
    return true;
  }
  
  public function end(ctx:RenderContext) {
    
  }
  
}

private class EffectCompositorEntry {
  
  public var composed:FloatBuffer;
  public var content:BatchDrawer;
  
  public function new(content:BatchDrawer) {
    composed = new FloatBuffer();
    this.content = content;
  }
  
  public function expand(min:Int, max:Int) {
    composed.grow(content.getBuffer(false).length);
  }
  
  public function begin() {
  }
  
  // TODO: Individual vertices
  
  public function addXY(index:Int, x:Float, y:Float) {
    final stride = BatchDrawer.getContentStride();
    var off = index * stride * 4;
    composed[off] += x;
    composed[off + 1] += y;
    
    composed[off + stride] += x;
    composed[off + stride + 1] += y;
    
    composed[off + stride * 2] += x;
    composed[off + stride * 2 + 1] += y;
    
    composed[off + stride * 3] += x;
    composed[off + stride * 3 + 1] += y;
  }
  
  public function mulAlpha(index:Int, a:Float) {
    final stride = BatchDrawer.getContentStride();
  }
  
}
class EffectCompositor {
  
  var data:Map<BatchDrawer, EffectCompositorEntry>;
  var composed:FloatBuffer;
  var output:FloatBuffer;
  
  public function new() {
    
  }
  
  public function clear() {
  }
  
  public function capture(content:BatchDrawer) {
    
  }
  
  public function begin() {
    
  }
  
  public function end() {
    
  }
  
}

// TODO: Figure out a way to do composite effects.
// @:noCompletion
class ContentDataCache {
  
  public var cache:FloatBuffer;
  public var count:Int;
  public var idx:Int;
  
  public function new() {
    cache = new FloatBuffer();
    count = 0;
  }
  
  public function clear() {
    cache = new FloatBuffer();
    count = 0;
  }
  
  public inline function add(val:Float) {
    cache.push(val);
    count++;
  }
  
  public inline function add2(v0:Float, v1:Float) {
    cache.push(v0);
    cache.push(v1);
    count++;
  }
  
  public inline function get():Float {
    return cache[idx++];
  }
  
  public inline function store1(src:FloatBuffer, offset:Int) {
    var dst = cache;
    final stride = RichTextContent.STRIDE;
    dst.push(src[offset]);
    dst.push(src[offset+stride]);
    dst.push(src[offset+stride*2]);
    dst.push(src[offset+stride*3]);
    count += 4;
  }
  
  public function storeRange2(src:FloatBuffer, start:Int, end:Int) {
    var dst = cache;
    final stride = RichTextContent.STRIDE;
    var offset = start * stride * 4;
    for (i in start...end) {
      dst.push(src[offset]);
      dst.push(src[offset + 1]);
      
      dst.push(src[offset+stride]);
      dst.push(src[offset+stride+1]);
      
      dst.push(src[offset+stride*2]);
      dst.push(src[offset+stride*2+1]);
      
      dst.push(src[offset+stride*3]);
      dst.push(src[offset+stride*3+1]);
      offset += stride * 4;
    }
    count += (end - start) * 4;
  }
  
  public inline function store2(src:FloatBuffer, offset:Int) {
    var dst = cache;
    final stride = RichTextContent.STRIDE;
    dst.push(src[offset]);
    dst.push(src[offset + 1]);
    
    dst.push(src[offset+stride]);
    dst.push(src[offset+stride+1]);
    
    dst.push(src[offset+stride*2]);
    dst.push(src[offset+stride*2+1]);
    
    dst.push(src[offset+stride*3]);
    dst.push(src[offset+stride*3+1]);
    count += 8;
  }
  
  public inline function store3(src:FloatBuffer, offset:Int) {
    var dst = cache;
    final stride = RichTextContent.STRIDE;
    dst.push(src[offset]);
    dst.push(src[offset + 1]);
    dst.push(src[offset + 2]);
    
    dst.push(src[offset+stride]);
    dst.push(src[offset+stride+1]);
    dst.push(src[offset+stride+2]);
    
    dst.push(src[offset+stride*2]);
    dst.push(src[offset+stride*2+1]);
    dst.push(src[offset+stride*2+2]);
    
    dst.push(src[offset+stride*3]);
    dst.push(src[offset+stride*3+1]);
    dst.push(src[offset+stride*3+2]);
    count += 12;
  }
  
  public inline function store4(src:FloatBuffer, offset:Int) {
    var dst = cache;
    final stride = RichTextContent.STRIDE;
    dst.push(src[offset]);
    dst.push(src[offset + 1]);
    dst.push(src[offset + 2]);
    dst.push(src[offset + 3]);
    
    dst.push(src[offset+stride]);
    dst.push(src[offset+stride+1]);
    dst.push(src[offset+stride+2]);
    dst.push(src[offset+stride+3]);
    
    dst.push(src[offset+stride*2]);
    dst.push(src[offset+stride*2+1]);
    dst.push(src[offset+stride*2+2]);
    dst.push(src[offset+stride*2+3]);
    
    dst.push(src[offset+stride*3]);
    dst.push(src[offset+stride*3+1]);
    dst.push(src[offset+stride*3+2]);
    dst.push(src[offset+stride*3+3]);
    count += 16;
  }
  
  public inline function offset1(dst:FloatBuffer, offset:Int, val:Float) {
    var src = cache;
    final stride = RichTextContent.STRIDE;
    var idx = this.idx;
    dst[offset] = src[idx] + val;
    dst[offset+stride] = src[idx+1] + val;
    dst[offset+stride*2] = src[idx+2] + val;
    dst[offset+stride*3] = src[idx+3] + val;
    this.idx += 4;
  }
  
  public inline function offset2(dst:FloatBuffer, offset:Int, val0:Float, val1:Float) {
    var src = cache;
    final stride = RichTextContent.STRIDE;
    var idx = this.idx;
    dst[offset  ] = src[idx] + val0;
    dst[offset+1] = src[idx+1] + val1;
    
    dst[offset+stride  ] = src[idx+2] + val0;
    dst[offset+stride+1] = src[idx+3] + val1;
    
    dst[offset+stride*2  ] = src[idx+4] + val0;
    dst[offset+stride*2+1] = src[idx+5] + val1;
    
    dst[offset+stride*3  ] = src[idx+6] + val0;
    dst[offset+stride*3+1] = src[idx+7] + val1;
    this.idx += 8;
  }
  
}