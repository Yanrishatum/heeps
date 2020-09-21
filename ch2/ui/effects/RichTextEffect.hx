package ch2.ui.effects;

import ch2.ui.RichText;
import ch2.BatchDrawer;
import h2d.RenderContext;

class RichTextEffect {
  
  public var once:Bool = false;
  public var active:Bool = true;
  public var frame:Int;
  
  public function new() {
    
  }
  
  public function reset() {
    
  }
  
  public function attach(content:BatchDrawer) {
    // When batcher with that compo is made.
  }
  
  public function init(content:BatchDrawer, start:Int, end:Int, node:NodeRange) {
    // On finalize
  }
  
  public function begin(content:BatchDrawer, ctx:RenderContext) {
    // Before sync
  }
  
  /** Return false when done. **/
  public function sync(content:BatchDrawer, ctx:RenderContext, start:Int, end:Int, node:NodeRange):Bool {
    return true;
  }
  
}