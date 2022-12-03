package gfx.common;

import haxe.ui.constants.SelectionMode;
import gfx.analysis.PeripheralEvent;
import gameboard.GameBoard.GameBoardEvent;
import net.shared.ServerEvent;
import haxe.ui.styles.Style;
import net.shared.PieceColor;
import gfx.utils.PlyScrollType;
import haxe.Timer;
import haxe.ui.components.VerticalScroll;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TableView;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
import net.shared.utils.MathUtils;
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

    private function onPlySelectedManually(num:Int)
    {
        onScrollRequested(Precise(num));
    }

    private function appendPlyStr(plyStr:String)
    {   
        if (currentSituation.turnColor == White)
        {
            var moveNum:Int = moveHistory.length + 1;
            var whiteData = {plyStr: plyStr, selected: false, onMoveSelected: onPlySelectedManually.bind(moveNum)};
            var blackData = {plyStr: "", selected: false, onMoveSelected: onPlySelectedManually.bind(moveNum + 1)};
            lastMovetableEntry = {"num": '$moveNum', "whiteMove": whiteData, "blackMove": blackData};
            movetable.dataSource.add(lastMovetableEntry);
        }
        else if (lastMovetableEntry == null)
        {
            var whiteData = {plyStr: "", selected: false, onMoveSelected: null};
            var blackData = {plyStr: plyStr, selected: false, onMoveSelected: onPlySelectedManually.bind(1)};
            lastMovetableEntry = {"num": '1', "whiteMove": whiteData, "blackMove": blackData};
            movetable.dataSource.add(lastMovetableEntry);
        }
        else
        {
            lastMovetableEntry.blackMove.plyStr = plyStr;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMovetableEntry);
        }

        updateScrollButtons();
    }

    private function onEditorToggled(editorActive:Bool)
    {
        disabled = editorActive;
    }

    private function rowIndexByPlyNum(plyNum:Int):Null<Int>
    {
        if (plyNum > 0)
            return startingSituation.turnColor == White? Math.floor((plyNum - 1) / 2) : Math.floor(plyNum / 2);
        else
            return null;
    }

    private function setMoveBold(plyNum:Int, bold:Bool)
    {
        if (plyNum <= 0)
            return;

        var moveColor:PieceColor = plyNum % 2 == 1? startingSituation.turnColor : opposite(startingSituation.turnColor);
        var rowIndex:Int = rowIndexByPlyNum(plyNum);
        var currentlySelectedRowData = movetable.dataSource.get(rowIndex);

        if (moveColor == White)
            currentlySelectedRowData.whiteMove.selected = bold;
        else
            currentlySelectedRowData.blackMove.selected = bold;

        movetable.dataSource.update(rowIndex, currentlySelectedRowData);
    }

    public function setShownMove(value:Int)
    {
        if (shownMove == value)
            return;

        if (shownMove > 0)
            setMoveBold(shownMove, false);

        shownMove = value;

        if (value > 0)
        {
            setMoveBold(value, true);
            scrollToShownMove();
        }
        else
            scrollTo(0);

        updateScrollButtons();
    }

    private function onHistoryDropped()
    {
        lastMovetableEntry = null;
        movetable.dataSource.clear();
    }

    private function scrollTo(relPos:Float)
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.min + relPos * (vscroll.max - vscroll.min);
    }

    private function scrollToShownMove()
    {
        if (shownMove == 0)
        {
            scrollTo(0);
            return;
        }

        var totalRows:Int = startingSituation.turnColor == White? Math.ceil(moveHistory.length / 2) : Math.ceil((moveHistory.length + 1) / 2);
        var neededRowIndex:Int = rowIndexByPlyNum(shownMove);

        var windowHeight:Float = movetable.height;
        var totalHeight:Float = movetable.contentHeight;
        var rowHeight:Float = totalHeight / totalRows;

        var neededRowCenterY:Float = neededRowIndex * rowHeight + rowHeight / 2;
        var relPos:Float = MathUtils.clamp((neededRowCenterY - windowHeight / 2) / (totalHeight - windowHeight), 0, 1);
        scrollTo(relPos);
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
        movetable.selectionMode = SelectionMode.DISABLED;
    }   
}