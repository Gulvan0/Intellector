package gfx.common;

import struct.IntPoint;
import net.EventProcessingQueue.INetObserver;
import gfx.analysis.IAnalysisPeripheralEventObserver;
import gameboard.GameBoard.IGameBoardObserver;
import haxe.Timer;
import gfx.game.LiveGameConstructor;
import gfx.analysis.PeripheralEvent;
import gameboard.GameBoard.GameBoardEvent;
import net.shared.ServerEvent;
import gfx.utils.PlyScrollType;
import struct.Ply;
import struct.Situation;
import haxe.ui.containers.VBox;
import net.shared.PieceColor;

abstract class PlyHistoryView extends VBox implements IGameBoardObserver implements IAnalysisPeripheralEventObserver implements INetObserver
{
    private var onScrollRequested:PlyScrollType->Void;
    private var startingSituation:Situation;
    private var currentSituation:Situation;
    private var moveHistory:Array<Ply>;
    public var shownMove(default, null):Int;

    private abstract function postInit():Void;
    private abstract function appendPlyStr(plyStr:String):Void;
    private abstract function onEditorToggled(editorActive:Bool):Void;
    private abstract function setShownMove(value:Int):Void;
    private abstract function onHistoryDropped():Void;
    private abstract function scrollToEnd():Void;

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
            case Move(fromI, toI, fromJ, toJ, morphInto, _):
                var ply:Ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto);
                appendPly(ply, true);
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
                Timer.delay(scrollToEnd, 50);
            case Precise(plyNum):
                setShownMove(plyNum);
        };
    }

    private function appendPly(ply:Ply, ?selectAfterwards:Bool = true)
    {
        appendPlyStr(ply.toNotation(currentSituation));
        currentSituation.makeMove(ply, true);
        moveHistory.push(ply);
        if (selectAfterwards)
            performScroll(End);
    }

    private function clear()
    {
        currentSituation = startingSituation.copy();
        moveHistory = [];
        onHistoryDropped();
        performScroll(Home);
    }

    private function rewrite(newPlySequence:Array<Ply>, newShownMove:Int):Void
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

    public function init(onScrollRequested:PlyScrollType->Void, constructor:ComponentConstructor)
    {
        this.onScrollRequested = onScrollRequested;
        this.moveHistory = [];
        this.shownMove = 0;

        switch constructor 
        {
            case Live(New(_, _, _, _, startingSituation, _)):
                this.startingSituation = startingSituation;
                this.currentSituation = startingSituation.copy();

            case Analysis(initialVariant):
                this.startingSituation = initialVariant.startingSituation;
                this.currentSituation = startingSituation.copy();
                for (ply in initialVariant.getMainLineBranch())
                    appendPly(ply, false);
                performScroll(End);

            case Live(Ongoing(parsedData, _, _)), Live(Past(parsedData, _)):
                this.startingSituation = parsedData.startingSituation;
                this.currentSituation = startingSituation.copy();
                for (ply in parsedData.movesPlayed)
                    appendPly(ply, false);
                performScroll(End);
        }

        postInit();
    }
    
    public function new()
    {
        super();
    }  
}