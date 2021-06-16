package;

import serialization.SituationDeserializer;
import struct.Situation;
import struct.PieceColor;
import openfl.display.Sprite;
import openfl.geom.Point;

class Factory 
{
    public static var a:Float = Field.a;

    public static function produceFiguresFromSerialized(serializedSituation:String, orientation:PieceColor, addOnto:Sprite):Array<Array<Null<Figure>>>
    {
        var situation = SituationDeserializer.deserialize(serializedSituation);
        return produceFiguresFromSituation(situation, orientation, addOnto);
    }    

    public static function produceFiguresFromDefault(orientation:PieceColor, addOnto:Sprite):Array<Array<Null<Figure>>>
    {
        var situation = Situation.starting();
        return produceFiguresFromSituation(situation, orientation, addOnto);
    }

    public static function produceFiguresFromSituation(situation:Situation, orientation:PieceColor, addOnto:Sprite):Array<Array<Null<Figure>>>
    {
        var figures = [for (j in 0...7) [for (i in 0...9) null]];

        for (p => hex in situation.collectOccupiedHexes())
        {
            var relativePoint = p.toRelative(orientation);
            figures[relativePoint.j][relativePoint.i] = Figure.fromHex(hex);
        }

        scaleMove(figures, addOnto);

        return figures;
    }

    public static function produceHexes(normalOrientation:Bool, addOnto:Sprite):Array<Array<Null<Hexagon>>>
    {
        var hexes:Array<Array<Null<Hexagon>>> = [];
        for (j in 0...7)
        {
            var row:Array<Hexagon> = [];
            for (i in 0...9)
                if (!Field.hexExists(i, j))
                    row.push(null);
                else 
                {
                    var hex:Hexagon = new Hexagon(a, i, j, normalOrientation);
                    var coords = Field.hexCoords(i, j);
                    hex.x = coords.x;
                    hex.y = coords.y;
                    addOnto.addChild(hex);
                    row.push(hex);
                }
            hexes.push(row);
        }
        return hexes;
    }

    private static function scaleMove(figures:Array<Array<Null<Figure>>>, addOnto:Sprite)
    {
        for (j in 0...7) 
            for (i in 0...9)
                if (figures[j][i] != null)
                    addFigure(figures[j][i], new IntPoint(i, j), addOnto);
    }

    public static function addFigure(fig:Figure, loc:IntPoint, addOnto:Sprite)
    {
        scaleFigure(fig);
        disposeFigure(fig, loc);
        addOnto.addChild(fig);
    }

    private static function scaleFigure(figure:Figure) 
    {
        var scale = Math.sqrt(3) * a * 0.85 / figure.height;
        if (figure.type == Progressor)
            scale *= 0.7;
        else if (figure.type == Liberator || figure.type == Defensor)
            scale *= 0.9;
        figure.scaleX = scale;
        figure.scaleY = scale;
    }

    private static function disposeFigure(figure:Figure, loc:IntPoint) 
    {
        var coords = Field.hexCoords(loc.i, loc.j);
        figure.x = coords.x;
        figure.y = coords.y;
    }
}