package ch2;

import h2d.RenderContext;
import h3d.mat.Stencil;
import h2d.Object;

@:access(h2d.RenderContext)
@:access(h3d.mat.Stencil)
@:access(h2d.Object)
class StencilMask extends Object {
  
  // Probably will have all sorts of bugs when using stencil-in-stencil, so who cares.
  static var inStencil:Int = 0;
  
  var stencil:Stencil;
  var old:Stencil;
  var killAlpha:Bool;
  
  public var mask:Object;
  public var reference:Int = 0xff;
  
  /**
    In case of using multi-stencil scenario, clearing the stencil buffer each frame may be sub-optimal.
  **/
  public var clearStencil:Bool = true;
  
  /**
    @param mask The object that provides the stencil mask area.
    Note that transparency have no correlation with stencil buffers, only actual geometry.
    Additionally, mask rendering will be forced to `Object.alpha` set to 0 and not visible during regular rendering.
  **/
  public function new(mask:Object, ?parent:Object) {
    this.mask = mask;
    mask.alpha = 0;
    mask.visible = false;
    stencil = new Stencil();
    stencil.setOp(Keep, Keep, Replace);
    this.reference = 0xff;
    super(parent);
  }
  
  override function drawRec(ctx:RenderContext)
  {
    old = ctx.pass.stencil;
    ctx.pass.stencil = stencil;
    killAlpha = ctx.killAlpha;
    ctx.killAlpha = false;
    
    if (inStencil == 0 && clearStencil) ctx.engine.clear(null, null, 0);
    inStencil++;
    stencil.frontTest = stencil.backTest = Always;
    stencil.writeMask = reference;
    stencil.reference = reference;
    
    mask.visible = true;
    mask.drawRec(ctx);
    mask.visible = false;
    
    stencil.frontTest = stencil.backTest = Equal;
    stencil.writeMask = 0;
    
    super.drawRec(ctx);
    
    ctx.pass.stencil = old;
    old = null;
    ctx.killAlpha = killAlpha;
    
    inStencil--;
  }
  
}