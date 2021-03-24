package;

import openfl.display.Sprite;
import openfl.geom.Point;

class Factory 
{
    public static var a:Float = Field.a;

    public static function produceFiguresFromSerialized(serializedPosition:String, addOnto:Sprite):Array<Array<Null<Figure>>>
    {
        var figures = Position.buildFigureArray(serializedPosition);
        scaleMove(figures, addOnto);
        return figures;
    }    

    public static function produceFiguresFromDefault(normalOrientation:Bool, addOnto:Sprite):Array<Array<Null<Figure>>>
    {
        var figures = Position.buildDefault(normalOrientation);
        scaleMove(figures, addOnto);
        return figures;
    }

    public static function produceHexes(addOnto:Sprite):Array<Array<Null<Hexagon>>>
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
                    var hex:Hexagon = new Hexagon(a, isDark(i, j));
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

    private static function isDark(i:Int, j:Int) 
    {
        if (j % 3 == 2)
            return false;
        else if (j % 3 == 0)
            return i % 2 == 0;
        else 
            return i % 2 == 1;
    }
}