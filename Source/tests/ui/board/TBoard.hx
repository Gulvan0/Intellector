package tests.ui.board;

import openfl.display.Sprite;
import struct.Ply;
import struct.Hex;
import struct.ReversiblePly;
import struct.IntPoint;
import struct.Situation;
import gameboard.Board;

class TBoard extends Sprite
{
    private var board:Board;

    private function _act_clear()
    {
        board.clearPieces();
    }

    @iterations(60)
    @interval(200)
    private function _auto_runningInt(i:Int)
    {
        if (i == 0)
            board.clearPieces();
        else
            board.setHexDirectly(IntPoint.fromScalar(i-1), Hex.occupied(Intellector, White));
    }

    private var _checks_runningInt:Array<String> = [
        'All hexes are visited',
        'Hexes are visited in order',
        'There is only one intellector at a time'
    ];

    @steps(10)
    private function _seq_setHex(i:Int)
    { 
        switch i
        {
            case 0: board.clearPieces();
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

    private var _checks_setHex:Map<Int, Array<String>> = [
        1 => ['White Int appears on 3;3'],
        2 => ['White Int teleports to 5;5'],
        3 => ['Black Int appears on 3;3'],
        4 => ['Black Liberator appears on 0;1'],
        5 => ['Black Liberator replaced with White Defensor'],
        6 => ['No changes'],
        7 => ['Black int goes down'],
        8 => ['Black int goes down'],
        9 => ['Black int replaced with White']
    ];

    private var revPly:ReversiblePly;

    @steps(8)
    private function _seq_transpositions(i:Int)
    { 
        switch i
        {
            case 0: 
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

    private var _checks_transpositions:Map<Int, Array<String>> = [
        1 => ['White Int goes up'],
        2 => ['Prev move is cancelled'],
        3 => ['Prev move is repeated'],
        4 => ['Orientation reverted correctly'],
        5 => ['Liberator captures Defensor'],
        6 => ['Orientation reverted correctly'],
        7 => ['Prev move is cancelled']
    ];

    public function new() 
    {
        super();

        board = new Board(Situation.starting());
        addChild(board);
    }
}