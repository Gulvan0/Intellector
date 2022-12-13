package gameboard;

import net.shared.board.RawPly;
import net.shared.board.MaterializedPly;
import haxe.exceptions.NotImplementedException;

class PlyHistory
{
    private var plys:Array<RawPly> = [];
    private var matPlys:Array<MaterializedPly> = [];
    public var pointer(default, null):Int = 0;

    public function getPlySequence():Array<RawPly> 
    {
        return plys.copy();
    }

    public function clear()
    {
        plys = [];
        matPlys = [];
        pointer = 0;
    }

    public function length():Int
    {
        return matPlys.length;
    }

    public function isAtBeginning():Bool
    {
        return pointer == 0;
    }

    public function isAtEnd():Bool
    {
        return pointer == length();
    }

    public function equalsNextMove(ply:MaterializedPly):Bool
    {
        return !isAtEnd() && matPlys[pointer].equals(ply);
    }

    public function getLastMove():Null<MaterializedPly>
    {
        return isAtBeginning()? null : matPlys[pointer-1];
    }

    public function home():Array<MaterializedPly>
    {
        var oldPointer:Int = pointer;
        pointer = 0;
        return matPlys.slice(0, oldPointer);
    }

    public function prev():Null<MaterializedPly>
    {
        if (pointer > 0)
        {
            pointer--;
            return matPlys[pointer];
        }
        else 
            return null;
    }

    public function next():Null<MaterializedPly>
    {
        if (pointer < matPlys.length)
        {
            pointer++;
            return matPlys[pointer-1];
        }
        else 
            return null;
    }

    public function end():Array<MaterializedPly>
    {
        var oldPointer:Int = pointer;
        pointer = matPlys.length;
        return matPlys.slice(oldPointer);
    }

    public function dropSinceShown()
    {
        plys = plys.slice(0, pointer);
        matPlys = matPlys.slice(0, pointer);
    }

    public function dropLast(cnt:Int):Array<MaterializedPly>
    {
        var newLength = matPlys.length - cnt;
        if (pointer > newLength)
            pointer = newLength;
        plys.splice(newLength, cnt);
        return matPlys.splice(newLength, cnt);
    }

    public function append(raw:RawPly, materialized:MaterializedPly) 
    {
        if (isAtEnd())
            pointer++;
        plys.push(raw);
        matPlys.push(materialized);
    }

    public function new()
    {

    }
}