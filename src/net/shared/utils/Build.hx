package net.shared.utils;

import haxe.macro.Expr.ExprOf;

class Build 
{
    public static macro function buildTime():ExprOf<Int>
    {
        var unixtime:Int = Std.int(UnixTimestamp.now().toUnixSeconds());
        return macro $v{unixtime};
    }
}