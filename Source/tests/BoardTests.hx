package tests;

import struct.Ply;
import struct.ReversiblePly;
import struct.Hex;
import struct.IntPoint;
import haxe.Timer;
import js.Browser;
import struct.Situation;
import gameboard.Board;
import openfl.display.Sprite;

class BoardTests extends Sprite
{
    public function simple()
    {
        var board:Board = new Board(Situation.starting());
        board.x = 200;
        board.y = 200;
        addChild(board);
        var i = 2;
        var timer = new Timer(1000);
        var revPly:ReversiblePly;
        timer.run = () -> {
            i++;
            switch i
            {
                case 5: board.clearPieces();
                case 6: board.setHexDirectly(new IntPoint(3, 3), Hex.occupied(Intellector, White));
                case 7: board.setHexDirectly(new IntPoint(5, 5), Hex.occupied(Intellector, White));
                case 8: board.setHexDirectly(new IntPoint(3, 3), Hex.occupied(Intellector, Black));
                case 9: board.setHexDirectly(new IntPoint(0, 1), Hex.occupied(Liberator, Black));
                case 10: board.setHexDirectly(new IntPoint(0, 1), Hex.occupied(Defensor, White));
                case 11: 
                    revPly = Ply.construct(new IntPoint(5, 5), new IntPoint(5, 4)).toReversible(board.shownSituation);
                    board.applyMoveTransposition(revPly);
                case 12: board.applyMoveTransposition(revPly, true);
                case 13: board.applyMoveTransposition(Ply.construct(new IntPoint(5, 5), new IntPoint(4, 5)).toReversible(board.shownSituation));
                case 14: board.setOrientation(Black);
                case 15: board.applyMoveTransposition(Ply.construct(new IntPoint(4, 5), new IntPoint(4, 4)).toReversible(board.shownSituation));
                case 16: board.setOrientation(White);
            }
        }
        
    }

    public function new()
    {
        super();
    }
}