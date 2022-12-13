package gfx.popups;

import gfx.basic_components.BaseDialog;
import browser.Url;
import haxe.ui.containers.dialogs.Dialog;
import utils.Changelog;
import dict.Dictionary;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/open_challenge_created_popup.xml'))
class OpenChallengeCreated extends BaseDialog
{
    private function resize()
    {
        width = Math.min(600, 0.98 * HaxeUIScreen.instance.actualWidth);
    }

    private function onClose(btn)
    {
        //* Do nothing
    }

    public function new(challengeID:Int)
    {
        super(RemovedOnGameStarted, false);
        linkText.copiedText = Url.getChallengeLink(challengeID);
    }
}