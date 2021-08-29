package cherry.soup;

import haxe.macro.Expr;
using haxe.macro.Tools;
macro function wref(expr:Expr, names:Array<Expr>):Expr {
  var tmps:Array<String> = [];
  var tmpDecl:Array<Expr> = [];
  var tmpAssign:Array<Expr> = [];
  for (n in names) {
    var tmpName = "__tmp_" + tmps.length;
    tmps.push(tmpName);
    tmpDecl.push(macro var $tmpName = $n);
    tmpAssign.push(macro $n = $i{tmpName});
  }
  function repl(e:Expr) {
    switch (e.expr) {
      case ECall(e, params):
        repl(e);
        for (p in params) repl(p);
      case EConst(Constant.CIdent("_")), EConst(Constant.CIdent("__")):
        e.expr = EConst(CIdent(tmps.shift()));
      case EField(e, field):
        repl(e);
      case EParenthesis(e):
        repl(e);
      case EBlock(exprs):
        for (e in exprs) repl(e);
      default:
    }
  }
  repl(expr);
  tmpDecl.push(macro var result = $e{expr});
  var result = tmpDecl.concat(tmpAssign);
  result.push(macro result);
  return macro $b{result};
}