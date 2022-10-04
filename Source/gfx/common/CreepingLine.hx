package gfx.common;

import haxe.Timer;
import haxe.ui.components.HorizontalScroll;
import net.shared.ServerEvent;
import gameboard.GameBoard.GameBoardEvent;
import gfx.analysis.PeripheralEvent;
import net.shared.PieceColor;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/creeping_line.xml"))
class CreepingLine extends PlyHistoryView
{
    private var plyCards:Array<CreepingLinePly> = [];

    private function onPlySelectedManually(num:Int)
    {
        onScrollRequested(Precise(num));
    }

    private function appendPlyStr(plyStr:String)
    {
        var moveNum:Int = moveHistory.length + 1;
        var plyCard:CreepingLinePly = new CreepingLinePly(moveNum, plyStr, onPlySelectedManually);

        plyCards.push(plyCard);
        lineBox.addComponent(plyCard);
    }

    private function onEditorToggled(editorActive:Bool)
    {
        hidden = editorActive;
    }

    private function setShownMove(value:Int)
    {
        if (shownMove > 0 && plyCards.length >= shownMove)
            plyCards[shownMove-1].deselect();
        shownMove = value;
        if (shownMove > 0)
            plyCards[shownMove-1].select();
    }

    private function onHistoryDropped()
    {
        for (card in plyCards)
            lineBox.removeComponent(card);
        plyCards = [];
    }

    private function scrollToEnd() 
    {
        var hscroll = runwaySV.findComponent(HorizontalScroll, false);
        if (hscroll != null)
            hscroll.pos = hscroll.max;
    }

    private function postInit()
    {
        //* Do nothing
    }

    public function new() 
    {
        super();
    }
}