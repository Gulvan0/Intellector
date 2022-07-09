package gameboard;

import haxe.exceptions.NotImplementedException;
import struct.Ply;
import struct.ReversiblePly;

class PlyHistory
{
    private var plys:Array<Ply> = [];
    private var revPlys:Array<ReversiblePly> = [];
    public var pointer(default, null):Int = 0;

    public function getPlySequence():Array<Ply> 
    {
        return plys.copy();
    }

    public function clear()
    {
        plys = [];
        revPlys = [];
        pointer = 0;
    }

    public function length():Int
    {
        return revPlys.length;
    }

    public function isAtBeginning():Bool
    {
        return pointer == 0;
    }

    public function isAtEnd():Bool
    {
        return pointer == revPlys.length;
    }

    public function equalsNextMove(ply:ReversiblePly):Bool
    {
        return !isAtEnd() && revPlys[pointer].equals(ply);
    }

    public function getLastMove():Null<ReversiblePly>
    {
        return isAtBeginning()? null : revPlys[pointer-1];
    }

    public function home():Array<ReversiblePly>
    {
        var oldPointer:Int = pointer;
        pointer = 0;
        return revPlys.slice(0, oldPointer);
    }

    public function prev():Null<ReversiblePly>
    {
        if (pointer > 0)
        {
            pointer--;
            return revPlys[pointer];
        }
        else 
            return null;
    }

    public function next():Null<ReversiblePly>
    {
        if (pointer < revPlys.length)
        {
            pointer++;
            return revPlys[pointer-1];
        }
        else 
            return null;
    }

    public function end():Array<ReversiblePly>
    {
        var oldPointer:Int = pointer;
        pointer = revPlys.length;
        return revPlys.slice(oldPointer);
    }

    public function dropSinceShown():Array<ReversiblePly>
    {
        plys = plys.slice(pointer);
        return revPlys = revPlys.slice(pointer);
    }

    public function dropLast(cnt:Int):Array<ReversiblePly>
    {
        var newLength = revPlys.length - cnt;
        if (pointer > newLength)
            pointer = newLength;
        plys.splice(newLength, cnt);
        return revPlys.splice(newLength, cnt);
    }

    public function append(ply:Ply, reversible:ReversiblePly, ?doNotIncrementPointerAtEnd:Bool = false) 
    {
        if (isAtEnd() && !doNotIncrementPointerAtEnd)
            pointer++;
        plys.push(ply);
        revPlys.push(reversible);
    }

    public function new()
    {

    }
}