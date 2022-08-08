package gfx.common;

import gfx.analysis.PeripheralEvent;
import gameboard.GameBoard.GameBoardEvent;
import net.ServerEvent;
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
class MoveNavigator extends VBox implements IPlyHistoryView
{
    private var firstColorToMove:PieceColor;
    private var plyCount:Int = 0;
    private var pointer:Int = 0;
    private var lastMovetableEntry:Dynamic;

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
            case ScrollBtnPressed(type):
                shiftPointer(type);
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
            case BranchingMove(_, plyStr, _, droppedMovesCount):
                revertPlys(droppedMovesCount);
                writePlyStr(plyStr, true);
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
                if (pointer < plyCount)
                    setPointer(pointer+1);
            case End:
                setPointer(plyCount);
            case Precise(plyNum):
                setPointer(plyNum);
        };
    }

    public function updateScrollButtons() 
    {
        homeBtn.disabled = pointer == 0;
        prevBtn.disabled = pointer == 0;
        nextBtn.disabled = pointer == plyCount;
        endBtn.disabled = pointer == plyCount;
    }

    public function setPointer(move:Int)
    {
        //TODO: Make selected move bold
        pointer = move;
        updateScrollButtons();
    }

    private function scrollAfterDelay() 
    {
        Timer.delay(scrollToEnd, 100);
    }

    public function scrollToEnd() 
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    public function writePlyStr(plyStr:String, selected:Bool)
    {
        plyCount++;
        
        var performedBy:PieceColor = plyCount % 2 == 1? firstColorToMove : opposite(firstColorToMove);

        if (performedBy == Black)
            if (plyCount == 1)
            {
                lastMovetableEntry = {"num": '1', "white_move": "", "black_move": plyStr};
                movetable.dataSource.add(lastMovetableEntry);
            }
            else
            {
                lastMovetableEntry.black_move = plyStr;
                movetable.dataSource.update(movetable.dataSource.size - 1, lastMovetableEntry);
            }
        else 
        {
            lastMovetableEntry = {"num": '$plyCount', "white_move": plyStr, "black_move": " "};
            movetable.dataSource.add(lastMovetableEntry);
        }

        if (selected)
            setPointer(plyCount);
        else
            updateScrollButtons();

        scrollAfterDelay();
    }

    public function writePly(ply:Ply, contextSituation:Situation) 
    {
        var plyStr = ply.toNotation(contextSituation);
        writePlyStr(plyStr, true);

        var supposedPlayerMoveColor:PieceColor = plyCount % 2 == 1? firstColorToMove : opposite(firstColorToMove);
        if (contextSituation.turnColor != supposedPlayerMoveColor)
            trace("WARNING: move order discrepancy in MoveNavigator::writePly()");
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt <= 0)
            return;
        
        plyCount -= cnt;

        if (pointer > plyCount)
            setPointer(plyCount);
        else
            updateScrollButtons();

        if (lastMovetableEntry.black_move == " ")
        {
            movetable.dataSource.removeAt(movetable.dataSource.size - 1);
            cnt--;
        }

        while (cnt >= 2)
        {
            movetable.dataSource.removeAt(movetable.dataSource.size - 1);
            cnt -= 2;
        }

        lastMovetableEntry = movetable.dataSource.get(movetable.dataSource.size - 1);
        if (cnt == 1)
        {
            lastMovetableEntry.black_move = " ";
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMovetableEntry);
        }

        scrollAfterDelay();
    }

    public function clear(?updatedFirstColorToMove:PieceColor)
    {
        pointer = 0;
        lastMovetableEntry = null;
        plyCount = 0;
        if (updatedFirstColorToMove != null)
            this.firstColorToMove = updatedFirstColorToMove;

        movetable.dataSource.clear();
        updateScrollButtons();
    }

    public function rewrite(newPlyStrSequence:Array<String>, newPointerPos:Int)
    {
        clear();
        for (plyStr in newPlyStrSequence)
            writePlyStr(plyStr, false);
        setPointer(newPointerPos);
    }
    
    public function actualize(pastMovesNotation:Array<String>)
    {
        for (plyStr in pastMovesNotation)
            writePlyStr(plyStr, false);
        shiftPointer(End);
    }

    public function init(firstColorToMove:PieceColor, onClickCallback:PlyScrollType->Void) 
    {
        this.firstColorToMove = firstColorToMove;
        homeBtn.onClick = onClickCallback.bind(Home).expand();
        prevBtn.onClick = onClickCallback.bind(Prev).expand();
        nextBtn.onClick = onClickCallback.bind(Next).expand();
        endBtn.onClick = onClickCallback.bind(End).expand();
        updateScrollButtons();
    } 
    
    public function new()
    {
        super();
    }   
}