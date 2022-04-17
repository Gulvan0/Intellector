package gfx.common;

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

    private function onCardClicked(move:Int)
    {
        deselectSelectedCard();
        plyCards[move-1].select();
        pointer = move;
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

        var plyCard:CreepingLinePly = new CreepingLinePly(move, plyStr, onCardClicked);

        if (selected)
        {
            deselectSelectedCard();
            plyCard.select();
            pointer = move;
        }

        plyCards.push(plyCard);
        lineBox.addComponent(plyCard);
    }

    public function shiftPointer(move:Int) 
    {
        deselectSelectedCard();
        plyCards[move-1].select();
        pointer = move;
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

    public function new(plySelected:Int->Void) 
    {
        super();
        this.plySelected = plySelected;
    }
}