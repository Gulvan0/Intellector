package gfx.game.common.ply_history_view;

import haxe.ui.core.Component;
import net.shared.board.Situation;
import net.shared.board.RawPly;
import net.shared.converters.Notation;
import net.shared.utils.MathUtils;
import haxe.Timer;
import haxe.ui.components.HorizontalScroll;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/creeping_line.xml"))
class CreepingLine extends PlyHistoryView
{
    private var plyCards:Array<CreepingLinePly> = [];
    private var selectedMoveNum:Int = 0;

    private function scrollTo(relPos:Float)
    {
        var hscroll = runwaySV.findComponent(HorizontalScroll, false);
        if (hscroll != null)
            hscroll.pos = hscroll.min + relPos * (hscroll.max - hscroll.min);
    }

    private function postInit():Void
    {
        //* Do nothing
    }

    private function appendPlyStr(moveNum:Int, ply:RawPly, situationBefore:Situation)
    {
        var plyStr:String = Notation.plyToNotation(ply, situationBefore, false, moveNum);
        var plyCard:CreepingLinePly = new CreepingLinePly(moveNum, plyStr, onPlySelectedManually);

        plyCards.push(plyCard);
        lineBox.addComponent(plyCard);
    }

    private function clear()
    {
        for (card in plyCards)
            lineBox.removeComponent(card);
        plyCards = [];
        selectedMoveNum = 0;
    }

    private function onEditorToggled(editorActive:Bool)
    {
        hidden = editorActive;
    }

    private function onShownMoveUpdated()
    {
        if (selectedMoveNum > 0 && plyCards.length >= selectedMoveNum)
            plyCards[selectedMoveNum-1].deselect();

        selectedMoveNum = genericModel.getShownMovePointer();

        if (selectedMoveNum > 0)
            plyCards[selectedMoveNum-1].select();

        refreshScrollPosition();
    }

    private function refreshElements()
    {
        //* Do nothing
    }

    private function refreshScrollPosition()
    {
        var shownMovePointer:Int = genericModel.getShownMovePointer();

        if (shownMovePointer == 0)
        {
            scrollTo(0);
            return;
        }

        var card = plyCards[shownMovePointer-1];
        var newScrollPos = MathUtils.clamp((card.left + card.width / 2 - runwaySV.width / 2) / (lineBox.width - runwaySV.width), 0, 1);
        scrollTo(newScrollPos);
    }

    public function asComponent():Component 
    {
        return this;
    }

    public function new() 
    {
        super();
    }
}