package tests.ui.board;

import tests.ui.TestedComponent.ComponentGraphics;
import openfl.display.Sprite;
import gameboard.Board;

class TBoard extends TestedComponent
{
    private var board:Board;
    
    public override function _provide_situation():Situation
    {
        return board.shownSituation;
    }

    private function _act_clear()
    {
        board.clearPieces();
    }

    @iterations(60)
    private function _seq_runningInt(i:Int)
    {
        if (i == 0)
        {
            update();
            board.clearPieces();
        }
        else
            board.setHexDirectly(IntPoint.fromScalar(i-1), Hex.occupied(Intellector, White));
    }

    @iterations(10)
    private function _seq_setHex(i:Int)
    { 
        switch i
        {
            case 0:
                update(); 
                board.clearPieces();
            case 1: board.setHexDirectly(new IntPoint(3, 3), Hex.occupied(Intellector, White));
            case 2: board.setHexDirectly(new IntPoint(5, 5), Hex.occupied(Intellector, White));
            case 3: board.setHexDirectly(new IntPoint(3, 3), Hex.occupied(Intellector, Black));
            case 4: board.setHexDirectly(new IntPoint(0, 1), Hex.occupied(Liberator, Black));
            case 5: board.setHexDirectly(new IntPoint(0, 1), Hex.occupied(Defensor, White));
            case 6: board.setHexDirectly(new IntPoint(5, 5), Hex.occupied(Intellector, White));
            case 7: board.setHexDirectly(new IntPoint(3, 4), Hex.occupied(Intellector, Black));
            case 8: board.setHexDirectly(new IntPoint(3, 5), Hex.occupied(Intellector, Black));
            case 9: board.setHexDirectly(new IntPoint(3, 5), Hex.occupied(Intellector, White));
        }
    }

    private var revPly:ReversiblePly;

    @iterations(8)
    private function _seq_transpositions(i:Int)
    { 
        switch i
        {
            case 0: 
                update();
                board.clearPieces();
                board.setHexDirectly(new IntPoint(5, 5), Hex.occupied(Intellector, White));
                board.setHexDirectly(new IntPoint(3, 3), Hex.occupied(Intellector, Black));
                board.setHexDirectly(new IntPoint(0, 1), Hex.occupied(Defensor, White));
                board.setHexDirectly(new IntPoint(2, 2), Hex.occupied(Liberator, Black));
                revPly = Ply.construct(new IntPoint(5, 5), new IntPoint(5, 4)).toReversible(board.shownSituation);
            case 1: 
                board.applyMoveTransposition(revPly);
            case 2: 
                board.applyMoveTransposition(revPly, true);
            case 3: 
                revPly = Ply.construct(new IntPoint(5, 5), new IntPoint(5, 4)).toReversible(board.shownSituation);
                board.applyMoveTransposition(revPly);
            case 4:
                board.setOrientation(Black);
            case 5:
                revPly = Ply.construct(new IntPoint(2, 2), new IntPoint(0, 1)).toReversible(board.shownSituation);
                board.applyMoveTransposition(revPly);
            case 6:
                board.setOrientation(White);
            case 7:
                board.applyMoveTransposition(revPly, true);
        }
    }

    private override function getComponent():ComponentGraphics
    {
		return Board(board);
    }

    private override function rebuildComponent()
    {
        board = new Board(Situation.starting());
    }
}