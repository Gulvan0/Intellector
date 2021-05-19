package;

import Figure.FigureType;
import Figure.FigureColor;

class Position
{
    public static function buildFigureArray(serializedPosition:String, watchedSide:FigureColor):Array<Array<Null<Figure>>>
    {
        var figures = [for (j in 0...7) [for (i in 0...9) null]];
        var inversed = watchedSide == Black;

        var ci = 1;
        while (ci < serializedPosition.length)
        {
            var i = Std.parseInt(serializedPosition.charAt(ci));
            var j = Std.parseInt(serializedPosition.charAt(ci + 1));
            var type = typeByCode(serializedPosition.charAt(ci + 2));
            var color = serializedPosition.charAt(ci + 3) == "w"? White : Black;

            if (inversed)
                j = inversedJ(i, j);

            figures[j][i] = new Figure(type, color);
            ci += 4;
        }

        return figures;
    }

    public static function buildDefault(normalOrientation:Bool):Array<Array<Null<Figure>>>
    {
        var playerColor = normalOrientation? White : Black;
        var enemyColour:FigureColor = normalOrientation? Black : White;
        var figures = [for (j in 0...7) [for (i in 0...9) null]];

        figures = [for (j in 0...7) [for (i in 0...9) null]];
        figures[0][0] = new Figure(Dominator, enemyColour);
        figures[0][1] = new Figure(Liberator, enemyColour);
        figures[0][2] = new Figure(Aggressor, enemyColour);
        figures[0][3] = new Figure(Defensor, enemyColour);
        figures[0][4] = new Figure(Intellector, enemyColour);
        figures[0][5] = new Figure(Defensor, enemyColour);
        figures[0][6] = new Figure(Aggressor, enemyColour);
        figures[0][7] = new Figure(Liberator, enemyColour);
        figures[0][8] = new Figure(Dominator, enemyColour);
        figures[1][0] = new Figure(Progressor, enemyColour);
        figures[1][2] = new Figure(Progressor, enemyColour);
        figures[1][4] = new Figure(Progressor, enemyColour);
        figures[1][6] = new Figure(Progressor, enemyColour);
        figures[1][8] = new Figure(Progressor, enemyColour);

        figures[6][0] = new Figure(Dominator, playerColor);
        figures[5][1] = new Figure(Liberator, playerColor);
        figures[6][2] = new Figure(Aggressor, playerColor);
        figures[5][3] = new Figure(Defensor, playerColor);
        figures[6][4] = new Figure(Intellector, playerColor);
        figures[5][5] = new Figure(Defensor, playerColor);
        figures[6][6] = new Figure(Aggressor, playerColor);
        figures[5][7] = new Figure(Liberator, playerColor);
        figures[6][8] = new Figure(Dominator, playerColor);
        figures[5][0] = new Figure(Progressor, playerColor);
        figures[5][2] = new Figure(Progressor, playerColor);
        figures[5][4] = new Figure(Progressor, playerColor);
        figures[5][6] = new Figure(Progressor, playerColor);
        figures[5][8] = new Figure(Progressor, playerColor);

        return figures;
    }

    private static function typeByCode(c:String):FigureType 
    {
        return switch c
        {
            case "r": Progressor;
            case "g": Aggressor;
            case "o": Dominator;
            case "e": Defensor;
            case "i": Liberator;
            case "n": Intellector;
            default: null;
        }
    }

    public static function inversedJ(i:Int, j:Int):Int
    {
        return 6 - j - i % 2;
    }

    public static function notationJ(i:Int, j:Int, normalOrientation:Bool):String
    {
        var newJ = 1 + (normalOrientation? Position.inversedJ(i, j) : j);
        return '$newJ';
    }

    public static function notationI(i:Int, normalOrientation:Bool):String
    {
        return String.fromCharCode('a'.code + (normalOrientation? i : (8 - i)));
    }
}