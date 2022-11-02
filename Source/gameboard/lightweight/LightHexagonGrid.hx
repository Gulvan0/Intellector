package gameboard.lightweight;

import struct.IntPoint;
import gfx.utils.Colors;
import utils.MathUtils;
import openfl.display.Shape;

class LightHexagonGrid extends Shape
{
    private inline function isDark(s:Int) 
    {
        if (s >= 54)
            return true;

        var i = s % 9;
        var j = Std.int(s / 9);

        if (j % 3 == 2)
            return false;
        else if (j % 3 == 0)
            return i % 2 == 0;
        else 
            return i % 2 == 1;
    }

    public function new(hexSideLength:Float) 
    {
        super();
        
        var hexHalfSide:Float = hexSideLength / 2;
        var hexHalfWidth:Float = Hexagon.sideToWidth(hexSideLength) / 2;
        var hexHalfHeight:Float = Hexagon.sideToHeight(hexSideLength) / 2;
        var rationalStep:Float = hexHalfSide;
        var irrationalStep:Float = rationalStep * Math.sqrt(3);

        graphics.lineStyle(MathUtils.scaleLike(3, 40, hexSideLength), Colors.border);

        var x:Float = hexHalfWidth;
        var y:Float = hexHalfHeight;
        var upper:Bool = true;

        for (s in 0...IntPoint.hexCount)
        {
            graphics.beginFill(Colors.hexFill(Normal, isDark(s)));
            graphics.moveTo(x-rationalStep, y-irrationalStep);
            graphics.lineTo(x+rationalStep, y-irrationalStep);
            graphics.lineTo(x+hexSideLength, y);
            graphics.lineTo(x+rationalStep, y+irrationalStep);
            graphics.lineTo(x-rationalStep, y+irrationalStep);
            graphics.lineTo(x-hexSideLength, y);
            graphics.lineTo(x-rationalStep, y-irrationalStep);
            graphics.endFill();
            
            if (s >= 54)
                x += 3 * hexSideLength;
            else if (s % 9 == 8)
            {
                x = hexHalfWidth;
                y += 2 * hexHalfHeight;
            }
            else if (upper)
            {
                x += 3 * hexHalfSide;
                y += hexHalfHeight;
                upper = false;
            }
            else
            {
                x += 3 * hexHalfSide;
                y -= hexHalfHeight;
                upper = true;
            }
        }
    }
}