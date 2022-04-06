package tests.ui.game;

import haxe.Timer;
import utils.TimeControl;
import gfx.game.GameInfoBox;
import openfl.display.Sprite;

class TGameInfoBox extends Sprite
{
    private var gameinfobox:GameInfoBox;

    public function new() 
    {
        super();
        gameinfobox = new GameInfoBox(new TimeControl(600, 0), "Gulvan", "kartoved");
        addChild(gameinfobox);
    }
}