package gfx.common;

import haxe.ui.components.Button;
import haxe.ui.containers.ButtonBar;
import dict.Dictionary;

enum Mode
{
    PlayerOngoingGame;
    PlayerGameEnded;
    Spectator;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/action_bar.xml"))
class ActionBar extends ButtonBar
{
    public function setMode(mode:Mode) 
    {
        var shownButtons:Array<Button> = switch mode 
        {
            case PlayerOngoingGame: [changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn];
            case PlayerGameEnded: [changeOrientationBtn, analyzeBtn, exportSIPBtn, rematchBtn];
            case Spectator: [changeOrientationBtn, analyzeBtn, exportSIPBtn];
        }
        changeActionButtons(shownButtons);
    }

    private function changeActionButtons(shownButtons:Array<Button>)
    {
        for (i in 0...numComponents)
            getComponentAt(i).hidden = true;

        var btnWidth:Float = 100 / shownButtons.length;
        for (btn in shownButtons)
        {
            btn.hidden = false;
            btn.percentWidth = btnWidth;
        }
    }

    public function new() 
    {
        super();    
    }
}