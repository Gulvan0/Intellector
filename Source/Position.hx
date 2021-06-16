package;

import serialization.SituationUnfolder;

class Position
{
    public static function buildDefault(normalOrientation:Bool, ?physical:Bool = true):Array<Array<Null<Figure>>>
    {
        var playerColor = normalOrientation? White : Black;
        var enemyColour:PieceColor = normalOrientation? Black : White;
        var figures = [for (j in 0...7) [for (i in 0...9) null]];

        figures = [for (j in 0...7) [for (i in 0...9) null]];
        figures[0][0] = new Figure(Dominator, enemyColour, physical);
        figures[0][1] = new Figure(Liberator, enemyColour, physical);
        figures[0][2] = new Figure(Aggressor, enemyColour, physical);
        figures[0][3] = new Figure(Defensor, enemyColour, physical);
        figures[0][4] = new Figure(Intellector, enemyColour, physical);
        figures[0][5] = new Figure(Defensor, enemyColour, physical);
        figures[0][6] = new Figure(Aggressor, enemyColour, physical);
        figures[0][7] = new Figure(Liberator, enemyColour, physical);
        figures[0][8] = new Figure(Dominator, enemyColour, physical);
        figures[1][0] = new Figure(Progressor, enemyColour, physical);
        figures[1][2] = new Figure(Progressor, enemyColour, physical);
        figures[1][4] = new Figure(Progressor, enemyColour, physical);
        figures[1][6] = new Figure(Progressor, enemyColour, physical);
        figures[1][8] = new Figure(Progressor, enemyColour, physical);

        figures[6][0] = new Figure(Dominator, playerColor, physical);
        figures[5][1] = new Figure(Liberator, playerColor, physical);
        figures[6][2] = new Figure(Aggressor, playerColor, physical);
        figures[5][3] = new Figure(Defensor, playerColor, physical);
        figures[6][4] = new Figure(Intellector, playerColor, physical);
        figures[5][5] = new Figure(Defensor, playerColor, physical);
        figures[6][6] = new Figure(Aggressor, playerColor, physical);
        figures[5][7] = new Figure(Liberator, playerColor, physical);
        figures[6][8] = new Figure(Dominator, playerColor, physical);
        figures[5][0] = new Figure(Progressor, playerColor, physical);
        figures[5][2] = new Figure(Progressor, playerColor, physical);
        figures[5][4] = new Figure(Progressor, playerColor, physical);
        figures[5][6] = new Figure(Progressor, playerColor, physical);
        figures[5][8] = new Figure(Progressor, playerColor, physical);

        return figures;
    }
}