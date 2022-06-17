package tests.ui.board;

import tests.ui.TestedComponent.ComponentGraphics;
import openfl.events.MouseEvent;
import openfl.display.Sprite;
import struct.IntPoint;
import struct.PieceColor.opposite;
import struct.Situation;
import gameboard.SelectableBoard;

class AugmentedSelectableBoard extends SelectableBoard
{
    private override function onClick(e:MouseEvent)
    {
        UITest.logHandledEvent("click");
        super.onClick(e);
    }

    private override function onRightPress(e:MouseEvent)
    {
        var location = posToIndexes(e.stageX, e.stageY);
        if (location != null)
            UITest.logHandledEvent('rpress|${location.i}|${location.j}');
        else
            UITest.logHandledEvent('rpress');
        super.onRightPress(e);
    }

    private override function onRightRelease(e:MouseEvent)
    {
        var location = posToIndexes(e.stageX, e.stageY);
        if (location != null)
            UITest.logHandledEvent('rrelease|${location.i}|${location.j}');
        else
            UITest.logHandledEvent('rrelease');
        super.onRightRelease(e);
    }

    public function _imitateEvent(encodedEvent:String)
    {
        var parts:Array<String> = encodedEvent.split('|');

        var event = new MouseEvent(MouseEvent.CLICK);
        if (parts.length > 1)
        {
            var pos = hexCoords(new IntPoint(Std.parseInt(parts[1]), Std.parseInt(parts[2])));
            event.stageX = pos.x;
            event.stageY = pos.y;
        }
        else
        {
            event.stageX = -1;
            event.stageY = -1;
        }

        switch parts[0]
        {
            case 'click':
                super.onClick(event);
            case 'rpress':
                super.onRightPress(event);
            case 'rrelease':
                super.onRightRelease(event);
            default:
                throw "Cant decode event: " + encodedEvent;
        }
    }
}

class TSelectableBoard extends TestedComponent
{
    private var board:AugmentedSelectableBoard;

    public override function _provide_situation():Situation
    {
        return board.shownSituation;
    }

    @iterations(8)
    private function _seq_basicSelectionTests(i:Int)
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

    @iterations(29)
    private function _seq_markers(i:Int)
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

    private function _act_flipBoard() 
    {
        board.setOrientation(opposite(board.orientationColor));
    }

    private override function getComponent():ComponentGraphics
    {
		return Board(board);
    }

    private override function rebuildComponent()
    {
        board = new AugmentedSelectableBoard(Situation.starting(), White, 50);
    }

    public override function imitateEvent(encodedEvent:String)
    {
        board._imitateEvent(encodedEvent);
    }
}