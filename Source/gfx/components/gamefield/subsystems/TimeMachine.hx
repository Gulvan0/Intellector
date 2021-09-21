package gfx.components.gamefield.subsystems;

import gfx.components.gamefield.common.Figure;
import struct.IntPoint;
import struct.HexTransform;
import struct.ReversiblePly;
import gfx.components.gamefield.modules.Field;
using Lambda;

class TimeMachine 
{
    public static function homePly(field:Field) 
    {
        undoSequence(field, field.plyHistory.slice(0, field.plyPointer), null);
        field.plyPointer = 0;
    }

    public static function prevPly(field:Field) 
    {
        if (field.plyPointer > 0)
        {
            undoSequence(field, [field.plyHistory[field.plyPointer-1]], field.plyPointer > 1? field.plyHistory[field.plyPointer-2] : null);
            field.plyPointer--;
        }
    }

    public static function nextPly(field:Field)
    {
        if (field.plyPointer < field.plyHistory.length)
        {
            redoSequence(field, [field.plyHistory[field.plyPointer]]);
            field.plyPointer++;
        }
    }

    public static function endPly(field:Field)
    {
        redoSequence(field, field.plyHistory.slice(field.plyPointer));
        field.plyPointer = field.plyHistory.length;
    }

    //----------------------------------------------------------------------------------------------------------

    /**Traverses the list starting from the last element (The list should be sorted chronologically)**/
    public static function undoSequence(field:Field, seq:Array<ReversiblePly>, ?previousPly:ReversiblePly)
    {
        if (seq.empty())
            return;

        var transforms:Array<HexTransform> = collapsePlySeq(seq);
        for (transform in transforms)
        {
            if (!transform.latter.isEmpty())
                field.removeChild(field.figures[transform.coords.j][transform.coords.i]);

            if (transform.former.isEmpty())
                field.figures[transform.coords.j][transform.coords.i] = null;
            else
            {
                var figure = Figure.fromHex(transform.former);
                Factory.addFigure(figure, transform.coords, field.orientationColor == White, field);
                field.figures[transform.coords.j][transform.coords.i] = figure;
            }
        }
        if (previousPly != null)
            field.highlightMove([for (transform in previousPly) transform.coords]);
        else 
            field.highlightMove([]);
    }

    private static function redoSequence(field:Field, seq:Array<ReversiblePly>)
    {
        if (seq.empty())
            return;

        var transforms:Array<HexTransform> = collapsePlySeq(seq);
        for (transform in transforms)
        {
            if (!transform.former.isEmpty())
                field.removeChild(field.figures[transform.coords.j][transform.coords.i]);

            if (transform.latter.isEmpty())
                field.figures[transform.coords.j][transform.coords.i] = null;
            else
            {
                var figure = Figure.fromHex(transform.latter);
                Factory.addFigure(figure, transform.coords, field.orientationColor == White, field);
                field.figures[transform.coords.j][transform.coords.i] = figure;
            }
        }
        field.highlightMove([for (transform in seq[seq.length - 1]) transform.coords]);
    }

    private static function collapsePlySeq(seq:Array<ReversiblePly>):Array<HexTransform>
    {
        var keys:Array<IntPoint> = [];
        var map:Map<IntPoint, HexTransform> = [];

        for (ply in seq)
            for (transform in ply)
            {
                var key = keys.find(transform.coords.equals);
                if (key != null)
                    map[key].latter = transform.latter;
                else
                {
                    map[transform.coords] = transform.copy();
                    keys.push(transform.coords);
                }
            }
        return map.array();   
    }    
}