package gfx.common;

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
                hidden = true;
            case DiscardChangesRequested:
                hidden = true;
            case EditorLaunchRequested:
                hidden = true;
            case ScrollBtnPressed(type):
                shiftPointer(type);
            case PlySelected(index):
                setPointer(index);
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(_, plyStr, _):
                writePlyStr(plyStr, true);
            case SubsequentMove(plyStr, _):
                shiftPointer(Next);
            case BranchingMove(ply, plyStr, performedBy, plyPointer, branchLength):
                revertPlys(branchLength - plyPointer);
                writePlyStr(plyStr, true);
            default:
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

    public function new() 
    {
        super();
    }
}