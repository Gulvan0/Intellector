package gfx.common;

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
    private var plyNumber:Int = 0;
    private var lastMovetableEntry:Dynamic;

    public function scrollAfterDelay() 
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
        plyNumber++;
        
        var performedBy:PieceColor = plyNumber % 2 == 1? firstColorToMove : opposite(firstColorToMove);

        if (performedBy == Black)
            if (plyNumber == 1)
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
            lastMovetableEntry = {"num": '$plyNumber', "white_move": plyStr, "black_move": " "};
            movetable.dataSource.add(lastMovetableEntry);
        }
    }

    public function writePly(ply:Ply, contextSituation:Situation) 
    {
        var plyStr = ply.toNotation(contextSituation);
        writePlyStr(plyStr, true);

        var supposedPlayerMoveColor:PieceColor = plyNumber % 2 == 1? firstColorToMove : opposite(firstColorToMove);
        if (contextSituation.turnColor != supposedPlayerMoveColor)
            trace("WARNING: move order discrepancy in MoveNavigator::writePly()");
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt <= 0)
            return;
        
        plyNumber -= cnt;

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
    }

    public function clear(?updatedFirstColorToMove:PieceColor)
    {
        movetable.dataSource.clear();
        lastMovetableEntry = null;
        plyNumber = 0;
        if (updatedFirstColorToMove != null)
            this.firstColorToMove = updatedFirstColorToMove;
    }

    public function rewrite(newPlyStrSequence:Array<String>)
    {
        clear();
        for (plyStr in newPlyStrSequence)
            writePlyStr(plyStr, true);
    }

    public function init(firstColorToMove:PieceColor, onClickCallback:PlyScrollType->Void) 
    {
        this.firstColorToMove = firstColorToMove;
        homeBtn.onClick = onClickCallback.bind(Home).expand();
        prevBtn.onClick = onClickCallback.bind(Prev).expand();
        nextBtn.onClick = onClickCallback.bind(Next).expand();
        endBtn.onClick = onClickCallback.bind(End).expand();
    } 
    
    public function new()
    {
        super();
    }   
}