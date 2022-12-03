package gfx.common;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import haxe.ui.events.UIEvent;
import serialization.GameLogParser.GameLogParserOutput;
import net.EventProcessingQueue.INetObserver;
import gfx.analysis.IAnalysisPeripheralEventObserver;
import gameboard.GameBoard.IGameBoardObserver;
import haxe.Timer;
import gfx.game.LiveGameConstructor;
import gfx.analysis.PeripheralEvent;
import gameboard.GameBoard.GameBoardEvent;
import net.shared.ServerEvent;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
import net.shared.PieceColor;

abstract class PlyHistoryView extends VBox implements IGameBoardObserver implements IAnalysisPeripheralEventObserver implements INetObserver
{
    private var isGamePlayable:Bool;
    private var onScrollRequested:PlyScrollType->Void;
    private var startingSituation:Situation;
    private var currentSituation:Situation;
    private var moveHistory:Array<RawPly>;
    public var shownMove(default, null):Int;

    private abstract function postInit():Void;
    private abstract function appendPlyStr(plyStr:String):Void;
    private abstract function onEditorToggled(editorActive:Bool):Void;
    private abstract function setShownMove(value:Int):Void;
    private abstract function onHistoryDropped():Void;
    private abstract function scrollToShownMove():Void;

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        Timer.delay(scrollToShownMove, 40);
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case BranchSelected(branch, _, pointer):
                rewrite(branch, pointer);
            case RevertNeeded(plyCnt):
                revertPlys(plyCnt);
            case ApplyChangesRequested:
                onEditorToggled(false);
            case DiscardChangesRequested:
                onEditorToggled(false);
            case EditorLaunchRequested:
                onEditorToggled(true);
            case ScrollBtnPressed(type):
                performScroll(type);
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(ply, _, _):
                appendPly(ply, true);
            case SubsequentMove(_, _):
                performScroll(Next);
            case BranchingMove(ply, _, _, droppedMovesCount):
                revertPlys(droppedMovesCount);
                appendPly(ply, true);
        }
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(ply, _):
                var selectMove:Bool = switch Preferences.autoScrollOnMove.get() 
                {
                    case Always: true;
                    case OwnGameOnly: isGamePlayable;
                    case Never: false;
                }
                appendPly(ply, selectMove);
            case Rollback(plysToUndo, _):
                revertPlys(plysToUndo);
            default:
        }
    }

    public function performScroll(type:PlyScrollType) 
    {
        switch type 
        {
            case Home: 
                setShownMove(0);
            case Prev: 
                if (shownMove > 0)
                    setShownMove(shownMove-1);
            case Next:
                if (shownMove < moveHistory.length)
                    setShownMove(shownMove+1);
            case End:
                setShownMove(moveHistory.length);
            case Precise(plyNum):
                setShownMove(plyNum);
        };
    }

    private function appendPly(ply:RawPly, ?selectAfterwards:Bool = true)
    {
        appendPlyStr(ply.toNotation(currentSituation));
        currentSituation.performRawPly(ply);
        moveHistory.push(ply);
        if (selectAfterwards)
            performScroll(End);
    }

    private function clear()
    {
        currentSituation = startingSituation.copy();
        moveHistory = [];
        shownMove = 0;
        onHistoryDropped();
    }

    private function rewrite(newPlySequence:Array<RawPly>, newShownMove:Int):Void
    {
        clear();
        for (ply in newPlySequence)
            appendPly(ply, false);
        performScroll(Precise(newShownMove));
    }

    private function revertPlys(cnt:Int):Void
    {
        var newLength:Int = moveHistory.length - cnt;
        if (cnt > 0 && newLength > 0)
            rewrite(moveHistory.slice(0, newLength), newLength);
    }

    public function updateStartingSituation(newStartingSituation:Situation)
    {
        startingSituation = newStartingSituation.copy();
        clear();
    }

    private function actualize(parsedData:GameLogParserOutput)
    {
        this.startingSituation = parsedData.startingSituation;
        this.currentSituation = startingSituation.copy();
        for (ply in parsedData.movesPlayed)
            appendPly(ply, false);
        performScroll(End);
    }

    public function init(onScrollRequested:PlyScrollType->Void, constructor:ComponentConstructor)
    {
        this.onScrollRequested = onScrollRequested;
        this.moveHistory = [];
        this.shownMove = 0;

        switch constructor 
        {
            case Live(New(_, _, _, _, startingSituation, _)):
                this.isGamePlayable = true;
                this.startingSituation = startingSituation;
                this.currentSituation = startingSituation.copy();

            case Analysis(initialVariant):
                this.isGamePlayable = false;
                this.startingSituation = initialVariant.startingSituation;
                this.currentSituation = startingSituation.copy();
                for (ply in initialVariant.getMainLineBranch())
                    appendPly(ply, false);
                performScroll(End);

            case Live(Ongoing(parsedData, _, _)):
                this.isGamePlayable = parsedData.isPlayerParticipant();
                actualize(parsedData);
                
            case Live(Past(parsedData, _)):
                this.isGamePlayable = false;
                actualize(parsedData);
        }

        postInit();
    }
    
    public function new()
    {
        super();
    }  
}