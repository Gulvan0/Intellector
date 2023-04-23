package gfx.live.common.ply_history_view;

import net.shared.board.Situation;
import net.shared.converters.Notation;
import net.shared.board.RawPly;
import haxe.ui.constants.SelectionMode;
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
import net.shared.utils.MathUtils;

using gfx.live.models.CommonModelExtractors;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/plynavigator.xml"))
class MoveNavigator extends PlyHistoryView
{
    private var lastMovetableEntry:Dynamic;
    private var selectedMoveNum:Int = 0;

    private function rowIndexByPlyNum(plyNum:Int, startingTurnColor:PieceColor):Null<Int>
    {
        if (plyNum > 0)
            return startingTurnColor == White? Math.floor((plyNum - 1) / 2) : Math.floor(plyNum / 2);
        else
            return null;
    }

    private function setMoveBold(plyNum:Int, bold:Bool)
    {
        if (plyNum <= 0)
            return;

        var startingTurnColor:PieceColor = genericModel.getStartingSituation().turnColor;
        var moveColor:PieceColor = plyNum % 2 == 1? startingTurnColor : opposite(startingTurnColor);
        var rowIndex:Int = rowIndexByPlyNum(plyNum, startingTurnColor);
        var currentlySelectedRowData = movetable.dataSource.get(rowIndex);

        if (moveColor == White)
            currentlySelectedRowData.whiteMove.selected = bold;
        else
            currentlySelectedRowData.blackMove.selected = bold;

        movetable.dataSource.update(rowIndex, currentlySelectedRowData);
    }

    private function scrollTo(relPos:Float)
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.min + relPos * (vscroll.max - vscroll.min);
    }

    private function postInit()
    {
        homeBtn.onClick = onScrollRequested.bind(Home);
        prevBtn.onClick = onScrollRequested.bind(Prev);
        nextBtn.onClick = onScrollRequested.bind(Next);
        endBtn.onClick = onScrollRequested.bind(End);
    }

    private function appendPlyStr(moveNum:Int, ply:RawPly, situationBefore:Situation)
    {
        var plyStr:String = Notation.plyToNotation(ply, situationBefore, false, null);

        if (lastPlyInfo.situationBefore.turnColor == White)
        {
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
    }

    private function clear()
    {
        lastMovetableEntry = null;
        selectedMoveNum = 0;
        movetable.dataSource.clear();
    }

    private function onEditorToggled(editorActive:Bool)
    {
        disabled = editorActive;
    }

    private function onShownMoveUpdated()
    {
        if (selectedMoveNum > 0)
            setMoveBold(shownMove, false);

        selectedMoveNum = genericModel.getShownMovePointer();

        if (selectedMoveNum > 0)
        {
            setMoveBold(selectedMoveNum, true);
            refreshScrollPosition();
        }
        else
            scrollTo(0);
    }

    private function refreshElements() 
    {
        var shownMovePointer:Int = genericModel.getShownMovePointer();
        var totalMoves:Int = genericModel.getLineLength();

        homeBtn.disabled = shownMovePointer == 0;
        prevBtn.disabled = shownMovePointer == 0;
        nextBtn.disabled = shownMovePointer == totalMoves;
        endBtn.disabled = shownMovePointer == totalMoves;
    }

    private function refreshScrollPosition()
    {
        var startingTurnColor:PieceColor = genericModel.getStartingSituation().turnColor;
        var shownMovePointer:Int = genericModel.getShownMovePointer();
        var totalMoves:Int = genericModel.getLineLength();

        if (shownMovePointer == 0)
        {
            scrollTo(0);
            return;
        }

        var totalRows:Int = startingTurnColor == White? Math.ceil(totalMoves / 2) : Math.ceil((totalMoves + 1) / 2);
        var neededRowIndex:Int = rowIndexByPlyNum(shownMovePointer, startingTurnColor);

        var windowHeight:Float = movetable.height;
        var totalHeight:Float = movetable.contentHeight;
        var rowHeight:Float = totalHeight / totalRows;

        var neededRowCenterY:Float = neededRowIndex * rowHeight + rowHeight / 2;
        var relPos:Float = MathUtils.clamp((neededRowCenterY - windowHeight / 2) / (totalHeight - windowHeight), 0, 1);
        scrollTo(relPos);
    }
    
    public function new()
    {
        super();
        movetable.selectionMode = SelectionMode.DISABLED;
    }   
}