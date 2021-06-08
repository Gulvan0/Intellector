package serialization;

import haxe.ds.Vector;

class Position
{
    public static var QUAD_CNT:Int = 7;

    public var v:Vector<Int>;

    public function read(from:Int, to:Int) 
    {
        var quadFrom = Std.int(from / 32);
        var quadTo = Std.int(to / 32);
        var localFrom = from % 32;
        var localTo = to % 32;
        
    }
    
    public function new() 
    {
        v = Vector.fromArrayCopy([for (i in 0...QUAD_CNT) 0]);
    }
}