package tests.ui.board;

import net.shared.board.MaterializedPly;
import net.shared.board.Hex;
import net.shared.board.RawPly;
import net.shared.board.HexCoords;
import tests.ui.TestedComponent.ComponentGraphics;
import gameboard.Board;
import net.shared.board.Situation;

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
            board.setHexDirectly(HexCoords.fromScalarCoord(i-1), Hex.construct(Intellector, White));
    }

    @iterations(10)
    private function _seq_setHex(i:Int)
    { 
        switch i
        {
            case 0:
                update(); 
                board.clearPieces();
            case 1: board.setHexDirectly(new HexCoords(3, 3), Hex.construct(Intellector, White));
            case 2: board.setHexDirectly(new HexCoords(5, 5), Hex.construct(Intellector, White));
            case 3: board.setHexDirectly(new HexCoords(3, 3), Hex.construct(Intellector, Black));
            case 4: board.setHexDirectly(new HexCoords(0, 1), Hex.construct(Liberator, Black));
            case 5: board.setHexDirectly(new HexCoords(0, 1), Hex.construct(Defensor, White));
            case 6: board.setHexDirectly(new HexCoords(5, 5), Hex.construct(Intellector, White));
            case 7: board.setHexDirectly(new HexCoords(3, 4), Hex.construct(Intellector, Black));
            case 8: board.setHexDirectly(new HexCoords(3, 5), Hex.construct(Intellector, Black));
            case 9: board.setHexDirectly(new HexCoords(3, 5), Hex.construct(Intellector, White));
        }
    }

    private var matPly:MaterializedPly;

    @iterations(8)
    private function _seq_transpositions(i:Int)
    { 
        switch i
        {
            case 0: 
                update();
                board.clearPieces();
                board.setHexDirectly(new HexCoords(5, 5), Hex.construct(Intellector, White));
                board.setHexDirectly(new HexCoords(3, 3), Hex.construct(Intellector, Black));
                board.setHexDirectly(new HexCoords(0, 1), Hex.construct(Defensor, White));
                board.setHexDirectly(new HexCoords(2, 2), Hex.construct(Liberator, Black));
                matPly = RawPly.construct(new HexCoords(5, 5), new HexCoords(5, 4)).toMaterialized(board.shownSituation);
            case 1: 
                board.applyMoveTransposition(matPly);
            case 2: 
                board.applyMoveTransposition(matPly, true);
            case 3: 
                matPly = RawPly.construct(new HexCoords(5, 5), new HexCoords(5, 4)).toMaterialized(board.shownSituation);
                board.applyMoveTransposition(matPly);
            case 4:
                board.setOrientation(Black);
            case 5:
                matPly = RawPly.construct(new HexCoords(2, 2), new HexCoords(0, 1)).toMaterialized(board.shownSituation);
                board.applyMoveTransposition(matPly);
            case 6:
                board.setOrientation(White);
            case 7:
                board.applyMoveTransposition(matPly, true);
        }
    }

    private override function getComponent():ComponentGraphics
    {
		return Board(board);
    }

    private override function rebuildComponent()
    {
        board = new Board(Situation.defaultStarting());
    }
}