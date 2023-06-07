package gfx.game.interfaces;

import gfx.utils.SpecialControlSettings;
import gfx.game.common.ComponentPageName;

interface IGameScreen
{
    public function setCompactSpecialControlSettings(settings:SpecialControlSettings):Void;
    public function setPageDisabled(page:ComponentPageName, pageDisabled:Bool):Void;
    public function setPageHidden(page:ComponentPageName, pageHidden:Bool):Void;
    public function displaySubscreen(page:ComponentPageName):Void;
    public function changeBehaviour(newBehaviour:IBehaviour):Void;
}