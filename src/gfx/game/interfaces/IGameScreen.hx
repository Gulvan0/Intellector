package gfx.game.interfaces;

import gfx.game.common.ComponentPageName;

interface IGameScreen
{
    public function setPageDisabled(page:ComponentPageName, pageDisabled:Bool):Void;
    public function setPageHidden(page:ComponentPageName, pageHidden:Bool):Void;
    public function displaySubscreen(page:ComponentPageName):Void;
}