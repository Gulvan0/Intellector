package gfx.popups;

import openfl.Assets;
import gfx.basic_components.SpriteWrapper;
import dict.Dictionary;
import gfx.basic_components.BaseDialog;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/reconnection_popup.xml'))
class ReconnectionDialog extends BaseDialog
{
    private function resize()
    {
        //* Do nothing
    }

    private function onClose(btn)
    {
        //* Do nothing
    }

    public function new() 
    {
        super(ReconnectionPopUp, true);
        
        var loadingAnimation:SpriteWrapper = new SpriteWrapper(Assets.getMovieClip("preloader:LogoPreloader"), true);
        loadingAnimation.x = animContainer.width / 2;
        loadingAnimation.y = animContainer.height / 2;
        animContainer.addChild(loadingAnimation);
    }
}