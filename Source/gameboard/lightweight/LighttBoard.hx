package gameboard.lightweight;

import net.shared.board.Situation;
import net.shared.PieceColor;
import openfl.display.Sprite;

class LightBoard extends Sprite
{
    public function new(situation:Situation, orientation:PieceColor, hexSideLength:Float, useHinting:Bool) 
    {
        super();
        cacheAsBitmap = true;

        addChild(new LightHexagonGrid(hexSideLength, useHinting));
        for (coords => pieceData in situation.collectPieces())
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

            var piece:LightPiece = new LightPiece(pieceData.type, pieceData.color, hexSideLength);

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