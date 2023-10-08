package cherry.soup;

import haxe.macro.Expr;
using haxe.macro.Tools;

/**
  Usage: `quickSet(IG.doStuff(_), IG.arrDouble2, x, y)`
**/
macro function quickSet(expr: Expr, toArr: Expr, names: Array<Expr>): Expr {
  var tmpDecl:Array<Expr> = [macro var __tmpArr = $toArr];
  var tmpAssign:Array<Expr> = [];
  for (i in 0...names.length) {
    var n = names[i];
    tmpDecl.push(macro __tmpArr[$v{i}] = @:privateAccess $n);
    tmpAssign.push(macro @:privateAccess $n = __tmpArr[$v{i}]);
  }
  
  function repl(e:Expr) {
    switch (e.expr) {
      case ECall(e, params):
        repl(e);
        for (p in params) repl(p);
      case EConst(Constant.CIdent("_")), EConst(Constant.CIdent("__")):
        e.expr = EConst(CIdent("__tmpArr"));
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