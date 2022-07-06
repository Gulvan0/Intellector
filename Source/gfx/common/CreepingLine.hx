package gfx.common;

import gameboard.GameBoard.GameBoardEvent;
import gfx.analysis.PeripheralEvent;
import struct.PieceColor;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/creeping_line.xml"))
class CreepingLine extends VBox implements IPlyHistoryView
{
    private var plySelected:Int->Void;
    private var plyCards:Array<CreepingLinePly> = [];
    private var pointer:Int = 0;
    private var firstColorToMove:PieceColor = White;


    private function handlePeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case BranchSelected(branch, branchStr, pointer):
                clear();
                for (plyStr in branchStr)
                    writePlyStr(plyStr, false);
                setPointer(pointer);
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
                setPointer(index+1);
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent) //TODO: Use in GameLayout; Check the overall logic there
    {
        switch event 
        {
            case ContinuationMove(_, plyStr, _):
                writePlyStr(plyStr, true);
            case SubsequentMove(plyStr, _):
                writePlyStr(plyStr, true);
            case BranchingMove(_, plyStr, _, _, _):
                writePlyStr(plyStr, true);
        }
    }

    private function getSelectedCard():Null<CreepingLinePly>
    {
        return pointer > 0? plyCards[pointer-1] : null;
    }

    private function setPointer(move:Int)
    {
        deselectSelectedCard();
        if (move > 0)
            plyCards[move-1].select();
        pointer = move;
    }

    private function onPlyCardClicked(move:Int)
    {
        setPointer(move);
        plySelected(move);
    }

    private function deselectSelectedCard() 
    {
        var card = getSelectedCard();
        if (card != null)
            card.deselect();
    }

    public function writePlyStr(plyStr:String, selected:Bool) //TODO: Why is it unused? GameLayout should reference it
    {
        var plyCardIndex:Int = plyCards.length;
        var move:Int = firstColorToMove == White? plyCardIndex + 1 : plyCardIndex + 2;

        var plyCard:CreepingLinePly = new CreepingLinePly(move, plyStr, onPlyCardClicked);

        if (selected)
        {
            deselectSelectedCard();
            plyCard.select();
            pointer = plyCardIndex + 1;
        }

        plyCards.push(plyCard);
        lineBox.addComponent(plyCard);
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

    public function revertPlys(cnt:Int) //TODO: Why is it unused? GameLayout should reference it
    {
        var newMoveCount = plyCards.length - cnt;
        if (pointer > newMoveCount)
        {
            deselectSelectedCard();
            if (newMoveCount > 0)
                plyCards[newMoveCount-1].select();
            pointer = newMoveCount;
        }
        for (card in plyCards.splice(newMoveCount, plyCards.length))
            lineBox.removeComponent(card);
    }

    public function rewrite(newPlyStrSequence:Array<String>)
    {
        clear();
        for (plyStr in newPlyStrSequence)
            writePlyStr(plyStr, true);
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

    public function init(plySelected:Int->Void, ?firstColorToMove:PieceColor = White) 
    {
        this.plySelected = plySelected;
        this.firstColorToMove = firstColorToMove;
    }

    public function new() 
    {
        super();
    }
}