package net.shared.utils;

import haxe.macro.Expr.ExprOf;

class Build 
{
    public static macro function buildTime():ExprOf<Int>
    {
        var unixtime:Int = Std.int(Date.now().getTime() / 1000);
        return macro $v{unixtime};
    }
}