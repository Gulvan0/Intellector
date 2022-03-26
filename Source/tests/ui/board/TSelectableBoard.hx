package tests.ui.board;

import openfl.display.Sprite;
import struct.IntPoint;
import struct.PieceColor.opposite;
import struct.Situation;
import gameboard.SelectableBoard;

class TSelectableBoard extends Sprite
{
    private var board:SelectableBoard;

    @steps(8)
    private function _seq_basics(i:Int)
    { 
        switch i
        {
            case 0: 
                board.setOrientation(White);
                board.setSituation(Situation.starting());
                board.highlightMove([]);
                for (coords in IntPoint.allHexCoords)
                    board.removeSingleMarker(coords);
            case 1: board.highlightMove([new IntPoint(0, 0), new IntPoint(2, 1)]);
            case 2: board.addMarkers(new IntPoint(0, 1));
            case 3: board.highlightMove([new IntPoint(2, 1), new IntPoint(4, 2)]);
            case 4: board.setOrientation(Black);
            case 5: board.removeMarkers(new IntPoint(0, 1));
            case 6: board.addMarkers(new IntPoint(4, 0));
            case 7: board.highlightMove([]);
        }
    }

    private var _checks_basics:Map<Int, Array<String>> = [
        -1 => ['Everything works the same with RMB hints'],
        0 => ['Starting pos, normal orientation, no highlighted moves, no markers'],
        1 => ['Upper left corner liberator jump highlighted'],
        2 => ['Markers added for the leftmost black progressor'],
        3 => ['The follow-up jump in the same direction highlighted instead of the former move'],
        4 => ['Highlighting rotated', 'Markers rotated'],
        5 => ['Markers removed'],
        6 => ['Markers added for black int'],
        7 => ['Move unhighlighted', 'Nothing else changed']
    ];

    @iterations(29)
    @interval(800)
    private function _auto_markers(i:Int)
    { 
        if (i == 0)
        {
            board.setOrientation(White);
            board.setSituation(Situation.starting());
            board.highlightMove([]);
            for (coords in IntPoint.allHexCoords)
                board.removeSingleMarker(coords);
        }
        else if (i == 1)
            board.addMarkers(IntPoint.fromScalar(0));
        else if (i <= 14)
        {
            board.removeMarkers(IntPoint.fromScalar(i-2));
            board.addMarkers(IntPoint.fromScalar(i-1));
        }
        else if (i == 15)
        {
            board.removeMarkers(IntPoint.fromScalar(i-2));
            board.addMarkers(IntPoint.fromScalar(IntPoint.hexCount - 14));
        }
        else if (i <= 28)
        {
            board.removeMarkers(IntPoint.fromScalar(IntPoint.hexCount - 14 + i - 16));
            board.addMarkers(IntPoint.fromScalar(IntPoint.hexCount - 14 + i - 15));
        }
    }

    private var _checks_markers:Array<String> = [
        'Markers are correct'
    ];

    private function _act_flipBoard() 
    {
        board.setOrientation(opposite(board.orientationColor));
    }

    private var _checks_flipBoard:Array<String> = [
        'RMB arrows drawable',
        'RMB selections drawable',
        'RMB arrows & arrows overlap nice',
        'RMB arrows & selections overlap nice',
        'RMB arrow disappears on 2nd draw attempt',
        'RMB arrow reappears on 3rd draw attempt',
        'RMB subsequent arrows look good',
        'RMB arrows & selections removed on LMB',
        'Same hex selectable after being removed',
        'Same arrow drawable after being removed', 
        'RMB hints rotate on flipBoard press', 
        'RMB arrows drawable correctly after flipBoard',
        'RMB selections drawable correctly after flipBoard'
    ];

    public function new() 
    {
        super();

        board = new SelectableBoard(Situation.starting(), White, 50);
        addChild(board);
    }    
}