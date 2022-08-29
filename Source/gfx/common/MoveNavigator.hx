package gfx.common;

import gfx.analysis.PeripheralEvent;
import gameboard.GameBoard.GameBoardEvent;
import net.shared.ServerEvent;
import haxe.ui.styles.Style;
import struct.PieceColor;
import gfx.utils.PlyScrollType;
import struct.Situation;
import struct.Ply;
import haxe.Timer;
import haxe.ui.components.VerticalScroll;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TableView;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/plynavigator.xml"))
class MoveNavigator extends PlyHistoryView
{
    private var lastMovetableEntry:Dynamic;

    private function postInit()
    {
        homeBtn.onClick = onScrollRequested.bind(Home).expand();
        prevBtn.onClick = onScrollRequested.bind(Prev).expand();
        nextBtn.onClick = onScrollRequested.bind(Next).expand();
        endBtn.onClick = onScrollRequested.bind(End).expand();
        updateScrollButtons();
    }

    private function appendPlyStr(plyStr:String)
    {   
        if (currentSituation.turnColor == White)
        {
            lastMovetableEntry = {"num": '${moveHistory.length + 1}', "white_move": plyStr, "black_move": " "};
            movetable.dataSource.add(lastMovetableEntry);
        }
        else if (lastMovetableEntry == null)
        {
            lastMovetableEntry = {"num": '1', "white_move": "", "black_move": plyStr};
            movetable.dataSource.add(lastMovetableEntry);
        }
        else
        {
            lastMovetableEntry.black_move = plyStr;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMovetableEntry);
        }

        updateScrollButtons();
    }

    private function onEditorToggled(editorActive:Bool)
    {
        disabled = editorActive;
    }

    public function setShownMove(value:Int)
    {
        //TODO: Make selected move bold
        shownMove = value;
        updateScrollButtons();
    }

    private function onHistoryDropped()
    {
        lastMovetableEntry = null;
        movetable.dataSource.clear();
    }

    private function scrollToEnd() 
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    private function updateScrollButtons() 
    {
        homeBtn.disabled = shownMove == 0;
        prevBtn.disabled = shownMove == 0;
        nextBtn.disabled = shownMove == moveHistory.length;
        endBtn.disabled = shownMove == moveHistory.length;
    }
    
    public function new()
    {
        super();
    }   
}