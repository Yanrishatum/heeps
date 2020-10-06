package ch2.ui.effects;

import ch2.ui.RichText;

class ShaderEffect<T:hxsl.Shader> extends RichTextEffect {
  
  public var shader:T;
  
  public function new(shader:T) {
    super();
    this.shader = shader;
  }
  
  override public function attach(content:RichTextRenderer)
  {
    content.addShader(shader);
  }
  
}