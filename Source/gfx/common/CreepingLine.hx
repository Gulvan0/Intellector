package gfx.common;

import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/creeping_line.xml"))
class CreepingLine extends VBox
{
    private var plySelected:Int->Void;
    private var plyCards:Array<CreepingLinePly> = [];
    private var pointer:Int = 0;

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

    public function writePly(plyStr:String, selected:Bool) 
    {
        var move:Int = plyCards.length + 1;

        var plyCard:CreepingLinePly = new CreepingLinePly(move, plyStr, onPlyCardClicked);

        if (selected)
        {
            deselectSelectedCard();
            plyCard.select();
            pointer = move;
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

    public function rollback(cnt:Int)
    {
        var newMoveCount = plyCards.length - cnt;
        if (pointer > newMoveCount)
        {
            deselectSelectedCard();
            plyCards[newMoveCount-1].select();
            pointer = newMoveCount;
        }
        for (card in plyCards.splice(newMoveCount, plyCards.length))
            lineBox.removeComponent(card);
    }

    public function init(plySelected:Int->Void) 
    {
        this.plySelected = plySelected;
    }

    public function new() 
    {
        super();
    }
}