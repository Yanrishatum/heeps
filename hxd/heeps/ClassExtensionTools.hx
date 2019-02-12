package hxd.heeps;

import haxe.macro.Expr;
import haxe.macro.Context;

class ClassExtensionTools
{
  
  public static function makeVar(fields:Array<Field>, name:String, access:Array<Access>, type:ComplexType, ?def:Expr, ?pos:Position, ?doc:String, ?meta:Metadata):Void
  {
    if (pos == null) pos = def != null ? def.pos : Context.currentPos();
    var f:Field = {
      name: name,
      access: access,
      kind: FieldType.FVar(type, def),
      pos: pos,
      doc: doc,
      meta: meta
    };
    fields.push(f);
  }
  
  public static function makeProp(fields:Array<Field>, name:String, access:Array<Access>, type:ComplexType, getter:Function, setter:Function, ?def:Expr, ?pos:Position, ?doc:String, ?meta:Metadata):Void
  {
    if (pos == null)
    {
      if (def != null) pos = def.pos;
      else pos = getter.expr.pos;
    }
    if (!getter.ret.equals(type) || !setter.ret.equals(type) || 
      getter.args.length != 0 || setter.args.length != 1 || !setter.args[0].type.equals(type))
        throw "Invalid getter or setter function!";
    
    var acc = access.indexOf(AStatic) != -1 ? [APrivate, AStatic] : [APrivate];
    makeProperty(fields, name, access, type, "get", "set", def, pos, doc, meta);
    makeFunc(fields, "get_" + name, acc, getter, pos);
    makeFunc(fields, "set_" + name, acc, setter, pos);
  }
  
  public static function makeProperty(fields:Array<Field>, name:String, access:Array<Access>, type:ComplexType, _get:String, _set:String, ?def:Expr, ?pos:Position, ?doc:String, ?meta:Metadata):Void
  {
    if (pos == null) pos = def != null ? def.pos : Context.currentPos();
        throw "Invalid getter or setter function!";
    var f:Field = {
      name: name,
      access: access,
      kind: FieldType.FProp(_get, _set, type, def),
      pos: pos,
      doc: doc,
      meta: meta
    };
    
    fields.push(f);
  }
  
  public static function makeFunc(fields:Array<Field>, name:String, access:Array<Access>, fn:Function, ?pos:Position, ?doc:String, ?meta:Metadata):Void
  {
    if (pos == null) pos = fn.expr.pos;
    var f:Field = {
      name: name,
      access: access,
      kind: FieldType.FFun(fn),
      pos: pos,
      doc: doc,
      meta: meta
    };
    
    fields.push(f);
  }
  
  public static function patchFunc(fields:Array<Field>, name:String, ?prepend:Expr, ?append:Expr, insertOldCode:Bool = true):Void
  {
    for (f in fields)
    {
      if (f.name == name)
      {
        switch(f.kind)
        {
          case FFun(f):
            var block:Array<Expr> = insertOldCode ? asBlock(f.expr) : [];
            if (prepend != null) block = asBlock(prepend).concat(block);
            if (append != null) block = block.concat(asBlock(append));
            f.expr = {
              expr: EBlock(block),
              pos: f.expr.pos
            };
          default:
            throw "Unexpected field type when patching a function!";
        }
      }
    }
  }
  
  public static function asBlock(e:Expr):Array<Expr>
  {
    switch (e.expr)
    {
      case EBlock(exprs):
        return exprs;
      default:
        return [e];
    }
  }
  
  public static function merge(self:Array<Field>, other:Array<Field>):Void
  {
    for (f in other)
    {
      var found = false;
      for (mf in self)
      {
        if (mf.name == f.name)
        {
          switch (mf.kind)
          {
            case FFun(mf):
              switch(f.kind)
              {
                case FFun(f):
                  var block = asBlock(f.expr);
                  crawl(block, "__super", asBlock(mf.expr));
                  mf.expr = {
                    expr: EBlock(block),
                    pos: f.expr.pos
                  };
                default:
                  throw "Invalid duplicate field type!";
              }
            default:
              throw "Invalid duplicate field type!";
          }
          found = true;
          break;
        }
      }
      if (!found) self.push(f);
    }
  }
  
  static function crawl(arr:Array<Expr>, lookFor:String, repl:Array<Expr>)
  {
    var i = 0;
    while (i < arr.length)
    {
      var e = arr[i];
      switch(e.expr)
      {
        case EBlock(exprs): crawl(exprs, lookFor, repl);
        case EConst(CIdent(s)) if (s == lookFor):
          arr[i] = repl[0];
          var j = 1;
          while (j < repl.length)
          {
            arr.insert(i+j, repl[j]);
            j++;
          }
          i += j - 1;
        default:
      }
      i++;
    }
  }
  
  public static function crawlPatch(e:Expr, shouldCrawl:Expr->Bool, callb:Expr->Expr, blockPart:Bool = false, isNullable:Bool = true):Expr
  {
    if (!shouldCrawl(e)) return e;
    
    var change = callb(e);
    if (change != e)
    {
      if (change == null)
      {
        if (isNullable)
           return blockPart ? null : macro {};
        else
          return e;
      }
      switch (change.expr)
      {
        case EBlock(exprs):
          if (exprs.length == 0)
          {
            if (isNullable)
               return blockPart ? null : macro {};
            else
              return e;
          }
        default:
      }
      return change;
    }
    switch(e.expr)
    {
      case EArray(e1, e2):
        var c1 = crawlPatch(e1, shouldCrawl, callb, false, false);
        var c2 = crawlPatch(e2, shouldCrawl, callb, false, false);
        if (c1 != e1 || c2 != e2) e.expr = EArray(c1, c2);
      case EBinop(op, e1, e2):
        var c1 = crawlPatch(e1, shouldCrawl, callb, false, false);
        var c2 = crawlPatch(e2, shouldCrawl, callb, false, false);
        if (c1 != e1 || c2 != e2) e.expr = EBinop(op, c1, c2);
      case EField(e, field):
        var c = crawlPatch(e, shouldCrawl, callb, false, false);
        if (c != e) e.expr = EField(c, field);
      case EParenthesis(e):
        var c = crawlPatch(e, shouldCrawl, callb, false, false);
        if (c != e) e.expr = EParenthesis(c);
      case ECall(e, params):
        var c = crawlPatch(e, shouldCrawl, callb, false, false);
        if (c != e) e.expr = ECall(c, params);
      // case EObjectDecl(fields):
      // case EArrayDecl(values):
      // case ENew(t, params):
      case EUnop(op, postFix, e):
        var c = crawlPatch(e, shouldCrawl, callb, false, false);
      // case EVars(vars):
      // case EFunction(name, f):
      case EBlock(exprs):
        var i = 0;
        while (i < exprs.length)
        {
          var c = crawlPatch(exprs[i], shouldCrawl, callb, true);
          if (c != exprs[i])
          {
            if (c == null)
            {
              exprs.remove(exprs[i]);
              continue;
            }
            switch(c.expr)
            {
              case EBlock(b):
                if (b.length == 0)
                {
                  exprs.remove(exprs[i]);
                  continue;
                }
                exprs[i] = b[0];
                var j = 1;
                while (j < b.length)
                {
                  exprs.insert(i+j, b[j]);
                  j++;
                }
                i += j - 1;
              default:
                exprs[i] = c;
            }
          }
          i++;
        }
      case EFor(it, expr):
        var itc = crawlPatch(it, shouldCrawl, callb, false, false);
        var ec = crawlPatch(expr, shouldCrawl, callb, false, false);
        if (it != itc || ec != expr) e.expr = EFor(itc, ec);
      case EIf(econd, eif, eelse):
        var c0 = crawlPatch(econd, shouldCrawl, callb, false, false);
        var c1 = crawlPatch(eif, shouldCrawl, callb, false, false);
        var c2 = eelse == null ? null : crawlPatch(eelse, shouldCrawl, callb, false, false);
        if (c0 != econd || eif != c1 || eelse != c2) e.expr = EIf(c0, c1, c2);
      case EWhile(econd, e, normalWhile):
        var c0 = crawlPatch(econd, shouldCrawl, callb, false, false);
        var c1 = crawlPatch(e, shouldCrawl, callb, false, false);
        if (c0 != econd || e != c1) e.expr = EWhile(c0, c1, normalWhile);
      // case ESwitch(e, cases, edef):
      // case ETry(e, catches):
      // case EReturn(e):
      // case EUntyped(e):
      // case EThrow(e):
      // case ECast(e, t):
      // case EDisplay(e, displayKind):
      // case ETernary(econd, eif, eelse):
      // case ECheckType(e, t):
      // case EMeta(s, e):
      default:
    }
    return e;
  }
  
  public static function getFunc(fields:Array<Field>, name:String):Function
  {
    for (f in fields)
    {
      if (f.name == name)
      {
        switch(f.kind)
        {
          case FFun(f): return f;
          default: throw "Expected function, got var/prop!";
        }
      }
    }
    return null;
  }
  
}