package gameboard.lightweight;

import net.shared.PieceColor;
import struct.Situation;
import openfl.display.Sprite;

class LightBoard extends Sprite
{
    public function new(situation:Situation, orientation:PieceColor, hexSideLength:Float) 
    {
        super();
        cacheAsBitmap = true;

        addChild(new LightHexagonGrid(hexSideLength));
        for (coords => hex in situation.collectOccupiedHexes())
        {
            var i:Int = coords.i;
            var j:Int = coords.j;

            if (orientation == Black)
            {
                j = 6 - j - i % 2;
                i = 8 - i;
            }

            var hexWidth:Float = Hexagon.sideToWidth(hexSideLength);
            var hexHeight:Float = Hexagon.sideToHeight(hexSideLength);

            var piece:LightPiece = new LightPiece(hex.type, hex.color, hexSideLength);

            piece.x = hexWidth / 2;
            piece.y = hexHeight / 2;

            piece.x += 3 * hexSideLength * i / 2;
            piece.y += hexHeight * j;

            if (i % 2 == 1)
                piece.y += hexHeight / 2;
            
            addChild(piece);
        }
    }
}