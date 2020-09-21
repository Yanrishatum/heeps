package ch2.ui.effects;

class ShaderEffect<T:hxsl.Shader> extends RichTextEffect {
  
  public var shader:T;
  
  public function new(shader:T) {
    super();
    this.shader = shader;
  }
  
  override public function attach(content:BatchDrawer)
  {
    content.addShader(shader);
  }
  
}