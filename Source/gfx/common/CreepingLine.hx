package gfx.common;

import haxe.Timer;
import haxe.ui.components.HorizontalScroll;
import net.ServerEvent;
import gameboard.GameBoard.GameBoardEvent;
import gfx.analysis.PeripheralEvent;
import struct.PieceColor;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/creeping_line.xml"))
class CreepingLine extends VBox implements IPlyHistoryView
{
    private var onPlySelectedManually:Int->Void;
    private var plyCards:Array<CreepingLinePly> = [];
    private var pointer:Int = 0;
    private var firstColorToMove:PieceColor = White;

    public function handlePeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case BranchSelected(branch, branchStr, pointer):
                rewrite(branchStr, pointer);
            case RevertNeeded(plyCnt):
                revertPlys(plyCnt);
            case ApplyChangesRequested(turnColor):
                clear(turnColor);
                hidden = false;
            case DiscardChangesRequested:
                hidden = false;
            case EditorLaunchRequested:
                hidden = true;
            case ScrollBtnPressed(type):
                shiftPointer(type);
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(_, plyStr, _):
                writePlyStr(plyStr, true);
            case SubsequentMove(_, _):
                shiftPointer(Next);
            case BranchingMove(_, plyStr, _, droppedMovesCount):
                revertPlys(droppedMovesCount);
                writePlyStr(plyStr, true);
        }
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Rollback(plysToUndo):
                revertPlys(plysToUndo);
            default:
        }
    }

    public function shiftPointer(type:PlyScrollType) 
    {
        switch type 
        {
            case Home: 
                setPointer(0);
            case Prev: 
                if (pointer > 0)
                    setPointer(pointer-1);
            case Next:
                if (pointer < plyCards.length)
                    setPointer(pointer+1);
            case End:
                setPointer(plyCards.length);
            case Precise(plyNum):
                setPointer(plyNum);
        };
    }

    public function setPointer(value:Int)
    {
        if (pointer > 0)
            plyCards[pointer-1].deselect();
        pointer = value;
        if (pointer > 0)
            plyCards[pointer-1].select();
    }

    public function writePlyStr(plyStr:String, selected:Bool)
    {
        var pointerPos:Int = plyCards.length + 1;
        var moveNum:Int = firstColorToMove == White? pointerPos : pointerPos + 1;

        var plyCard:CreepingLinePly = new CreepingLinePly(pointerPos, moveNum, plyStr, onPlySelectedManually);

        plyCards.push(plyCard);
        lineBox.addComponent(plyCard);

        if (selected)
            setPointer(pointerPos);

        Timer.delay(scrollToEnd, 50);
    }

    public function scrollToEnd() 
    {
        var hscroll = runwaySV.findComponent(HorizontalScroll, false);
        if (hscroll != null)
            hscroll.pos = hscroll.max;
    }

    public function revertPlys(cnt:Int)
    {
        var newMoveCount = plyCards.length - cnt;
        if (pointer > newMoveCount)
            setPointer(newMoveCount);

        for (card in plyCards.splice(newMoveCount, plyCards.length))
            lineBox.removeComponent(card);
    }

    public function rewrite(newPlyStrSequence:Array<String>, newPointerPos:Int)
    {
        clear();
        for (plyStr in newPlyStrSequence)
            writePlyStr(plyStr, true);
        setPointer(newPointerPos);
    }

    public function clear(?updatedFirstColorToMove:PieceColor)
    {
        pointer = 0;
        for (card in plyCards)
            lineBox.removeComponent(card);
        plyCards = [];
        
        if (updatedFirstColorToMove != null)
            firstColorToMove = updatedFirstColorToMove;
    }

    public function init(onPlySelectedManually:Int->Void, ?firstColorToMove:PieceColor = White) 
    {
        this.onPlySelectedManually = onPlySelectedManually;
        this.firstColorToMove = firstColorToMove;
    }

    public function actualize(pastMovesNotation:Array<String>)
    {
        for (plyStr in pastMovesNotation)
            writePlyStr(plyStr, false);
        shiftPointer(End);
    }

    public function new() 
    {
        super();
    }
}