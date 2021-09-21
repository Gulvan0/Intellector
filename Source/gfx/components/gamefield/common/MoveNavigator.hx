package gfx.components.gamefield.common;

import gfx.utils.PlyScrollType;
import struct.Situation;
import struct.Ply;
import haxe.Timer;
import haxe.ui.components.VerticalScroll;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TableView;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
using utils.CallbackTools;

class MoveNavigator extends VBox
{
    private var movetable:TableView;

    private var plyNumber:Int;
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

    public function writePly(ply:Ply, contextSituation:Situation) 
    {
        var moveStr = ply.toNotation(contextSituation);

        if (contextSituation.turnColor == Black)
        {
            lastMovetableEntry.black_move = moveStr;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMovetableEntry);
        }
        else 
        {
            lastMovetableEntry = {"num": '$plyNumber', "white_move": moveStr, "black_move": " "};
            movetable.dataSource.add(lastMovetableEntry);
        }

        plyNumber++;
    }

    public function revertPlys(cnt:Int) 
    {
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

    private function buildPlyScrollBtn(type:PlyScrollType, onClick:Void->Void):Button
    {
        var btnText:String = switch type 
        {
            case Home: "❙◄◄";
            case Prev: "◄";
            case Next: "►";
            case End: "►►❙";
        };

        var btn:Button = new Button();
		btn.width = (250 - 5.3 * 3) / 4;
		btn.text = btnText;
        btn.onClick = onClick.expand();
        return btn;
    }

    private function constructControls(onClickCallback:PlyScrollType->Void):HBox
    {
        var matchViewControls:HBox = new HBox();

        for (type in PlyScrollType.createAll())
        {
            var callback:Void->Void = onClickCallback.bind(type);
            var btn:Button = buildPlyScrollBtn(type, callback);
            matchViewControls.addComponent(btn);
        }

        return matchViewControls;
    }

    public function new(onClickCallback:PlyScrollType->Void) 
    {
        super();
        plyNumber = 1;

        var matchViewControls = constructControls(onClickCallback);
        addComponent(matchViewControls);

        movetable = ComponentMacros.buildComponent("assets/layouts/movetable.xml");
        addComponent(movetable);
    }    
}