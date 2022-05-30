package tests.ui.board;

import tests.ui.TestedComponent;
import struct.IntPoint;
import openfl.events.MouseEvent;
import gfx.components.Dialogs;
import gfx.utils.PlyScrollType;
import tests.ui.ArgumentType;
import struct.Situation;
import haxe.Timer;
import serialization.PlySerializer;
import struct.Ply;
import gameboard.behaviors.AnalysisBehavior;
import struct.PieceColor;
import gameboard.behaviors.EnemyMoveBehavior;
import gameboard.states.StubState;
import gameboard.behaviors.PlayerMoveBehavior;
import gameboard.states.NeutralState;
import gameboard.GameBoard;
import openfl.display.Sprite;

class AugmentedGameBoard extends GameBoard
{
    private override function onClick(e:MouseEvent)
    {
        UITest.logHandledEvent("click");
        super.onClick(e);
    }
    
    private override function onLMBPressed(e:MouseEvent)
    {
        var location = posToIndexes(e.stageX, e.stageY);
        if (location != null)
            UITest.logHandledEvent('lpress|${e.shiftKey? "T" : "F"}|${e.ctrlKey? "T" : "F"}|${location.i}|${location.j}');
        else
            UITest.logHandledEvent('lpress|${e.shiftKey? "T" : "F"}|${e.ctrlKey? "T" : "F"}');
        super.onRightPress(e);
    }

    private override function onLMBReleased(e:MouseEvent)
    {
        var lastMoveLocation = posToIndexes(lastMouseMoveEvent.stageX, lastMouseMoveEvent.stageY);
        if (lastMoveLocation != null)
            UITest.logHandledEvent('move|${lastMoveLocation.i}|${lastMoveLocation.j}');
        else
            UITest.logHandledEvent('move');

        var location = posToIndexes(e.stageX, e.stageY);
        if (location != null)
            UITest.logHandledEvent('lrelease|${e.shiftKey? "T" : "F"}|${e.ctrlKey? "T" : "F"}|${location.i}|${location.j}');
        else
            UITest.logHandledEvent('lrelease|${e.shiftKey? "T" : "F"}|${e.ctrlKey? "T" : "F"}');
        super.onRightRelease(e);
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
        if (parts.length == 5)
        {
            var pos = hexCoords(new IntPoint(Std.parseInt(parts[3]), Std.parseInt(parts[4])));
            event.shiftKey = parts[1] == "T";
            event.ctrlKey = parts[2] == "T";
            event.stageX = pos.x;
            event.stageY = pos.y;
        }
        else if (parts.length == 3)
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
            case 'lpress':
                super.onLMBPressed(event);
            case 'lrelease':
                super.onLMBReleased(event);
            case 'move':
                super.onMouseMoved(event);
            default:
                throw "Cant decode event: " + encodedEvent;
        }
    }

}

class TGameBoard extends TestedComponent
{
    private var board:AugmentedGameBoard;

    public override function _provide_situation():Situation
    {
        return board.shownSituation;
    }

    @prompt("AEnumerable", "Behavior", ["PlayerMove", "EnemyMove", "Analysis"], "Player color", ["White", "Black"])
    private function _act_setBehavior(type:String, color:String)
    {
        var playerColor:PieceColor = PieceColor.createByName(color);
        if (type == "PlayerMove")
        {
            board.state = new NeutralState();
            board.behavior = new PlayerMoveBehavior(playerColor);
        }
        else if (type == "EnemyMove")
        {
            board.state = Preferences.premoveEnabled.get()? new NeutralState() : new StubState();
            board.behavior = new PlayerMoveBehavior(playerColor);
        }
        else
        {
            board.state = new NeutralState();
            board.behavior = new AnalysisBehavior(playerColor);
        }
        board.plyHistory.clear();
    }

    @prompt("APly", "Enemy move")
    private function _act_enemyMove(ply:Ply) 
    {
        board.handleNetEvent(Move(ply.from.i, ply.to.i, ply.from.j, ply.to.j, ply.morphInto == null? null : ply.morphInto.getName()));
    }

    @prompt("AInt", "Moves to cancel")
    private function _act_rollback(cnt:Int) 
    {
        board.handleNetEvent(Rollback(cnt));
    }

    @prompt("AInt", "Delay in ms")
    private function _act_endGame(delay:Int) 
    {
        Timer.delay(() -> {board.handleNetEvent(GameEnded('NONE', 'NONE'));}, delay);
    }

    //TODO: Deprecate when there will be a way to edit settings in testing environment
    private function _act_togglePremoves() 
    {
        Preferences.premoveEnabled.set(!Preferences.premoveEnabled.get());
    }

    private function _act_printHistory() 
    {
        output(Ply.plySequenceToNotation(board.plyHistory.getPlySequence(), Situation.starting()).join(" > "));
    }

    @split(["<<", "<", ">", ">>"])
    private function _act_scroll(scrollType:String) 
    {
        var plyScrollType:PlyScrollType = switch scrollType 
        {
            case "<<": Home;
            case "<": Prev;
            case ">": Next;
            case ">>": End;
            default: null;
        }
        board.applyScrolling(plyScrollType);
    }

    private function _act_revertOrientation()
    {
        board.revertOrientation();
    }

    private override function getComponent():ComponentGraphics
    {
		return Sprite(board);
    }

    private override function rebuildComponent()
    {
        board = new AugmentedGameBoard(Situation.starting(), White, new EnemyMoveBehavior(White), false, 50);
    }

    public override function _imitateEvent(encodedEvent:String)
    {
        board._imitateEvent(encodedEvent);
    }
}