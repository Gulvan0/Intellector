package gfx.popups;

import browser.Url;
import utils.MathUtils;
import haxe.ui.containers.dialogs.Dialog;
import utils.Changelog;
import dict.Dictionary;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/open_challenge_created_popup.xml'))
class OpenChallengeCreated extends Dialog
{
    private function resize()
    {
        width = Math.min(600, 0.98 * HaxeUIScreen.instance.actualWidth);
    }

    public function onClose(?e)
    {
        SceneManager.removeResizeHandler(resize);
    }

    public function new(challengeID:Int)
    {
        super();
        linkText.copiedText = Url.getChallengeLink(challengeID);

        resize();
        SceneManager.addResizeHandler(resize);
    }
}