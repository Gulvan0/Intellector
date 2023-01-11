package gfx.common;

import net.shared.utils.MathUtils;
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
        var moveNum:Int = moveHistory.length;
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

        scrollToShownMove();
    }

    private function onHistoryDropped()
    {
        for (card in plyCards)
            lineBox.removeComponent(card);
        plyCards = [];
    }

    private function scrollTo(relPos:Float)
    {
        var hscroll = runwaySV.findComponent(HorizontalScroll, false);
        if (hscroll != null)
            hscroll.pos = hscroll.min + relPos * (hscroll.max - hscroll.min);
    }

    private function scrollToShownMove()
    {
        if (shownMove == 0)
        {
            scrollTo(0);
            return;
        }

        var card = plyCards[shownMove-1];
        var newScrollPos = MathUtils.clamp((card.left + card.width / 2 - runwaySV.width / 2) / (lineBox.width - runwaySV.width), 0, 1);
        scrollTo(newScrollPos);
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