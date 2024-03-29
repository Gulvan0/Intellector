package tests.ui.board;

import net.shared.board.HexCoords;
import net.shared.PieceColor;
import tests.ui.TestedComponent.ComponentGraphics;
import net.shared.PieceColor.opposite;
import gameboard.SelectableBoard;
import net.shared.board.Situation;

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
            var pos = hexCoords(new HexCoords(Std.parseInt(parts[1]), Std.parseInt(parts[2])));
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
                throw "Can't decode event: " + encodedEvent;
        }
    }
}

@:access(gameboard.SelectableBoard)
class TSelectableBoard extends TestedComponent
{
    private var board:AugmentedSelectableBoard;

    private var _initparam_arrowSelectionMode:SelectionMode = Free;
    private var _initparam_hexSelectionMode:SelectionMode = Free;
    private var _initparam_orientationColor:PieceColor = White;

    public override function _provide_situation():Situation
    {
        return board.shownSituation;
    }

    @iterations(8)
    private function _seq_basicSelectionTests(i:Int)
    { 
        switch i
        {
            case 0: update();
            case 1: board.highlightMove([new HexCoords(0, 0), new HexCoords(2, 1)]);
            case 2: board.addMarkers(new HexCoords(0, 1));
            case 3: board.highlightMove([new HexCoords(2, 1), new HexCoords(4, 2)]);
            case 4: board.setOrientation(Black);
            case 5: board.removeMarkers(new HexCoords(0, 1));
            case 6: board.addMarkers(new HexCoords(4, 0));
            case 7: board.highlightMove([]);
        }
    }

    @iterations(29)
    private function _seq_markers(i:Int)
    { 
        if (i == 0)
            update();
        else if (i == 1)
            board.addMarkers(HexCoords.fromScalarCoord(0));
        else if (i <= 14)
        {
            board.removeMarkers(HexCoords.fromScalarCoord(i-2));
            board.addMarkers(HexCoords.fromScalarCoord(i-1));
        }
        else if (i == 15)
        {
            board.removeMarkers(HexCoords.fromScalarCoord(i-2));
            board.addMarkers(HexCoords.fromScalarCoord(HexCoords.hexCount() - 14));
        }
        else if (i <= 28)
        {
            board.removeMarkers(HexCoords.fromScalarCoord(HexCoords.hexCount() - 14 + i - 16));
            board.addMarkers(HexCoords.fromScalarCoord(HexCoords.hexCount() - 14 + i - 15));
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
        board = new AugmentedSelectableBoard(Situation.defaultStarting(), _initparam_arrowSelectionMode, _initparam_hexSelectionMode, _initparam_orientationColor, 50);
    }

    public override function imitateEvent(encodedEvent:String)
    {
        board._imitateEvent(encodedEvent);
    }

    public override function onDialogShown()
    {
        board.suppressRMBHandler = true;
    }

    public override function onDialogHidden()
    {
        board.suppressRMBHandler = false;
    }
}