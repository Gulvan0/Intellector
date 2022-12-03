package gfx.popups;

import net.shared.utils.MathUtils;
import haxe.ui.containers.dialogs.Dialog;
import utils.Changelog;
import dict.Dictionary;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/changelog_popup.xml'))
class ChangelogDialog extends Dialog
{
    private function resize()
    {
        width = Math.min(1000, 0.9 * HaxeUIScreen.instance.actualWidth);
        height = Math.min(450, 0.7 * HaxeUIScreen.instance.actualHeight);
        changesLabel.customStyle = {fontSize: MathUtils.clamp(0.013 * HaxeUIScreen.instance.actualHeight, 12, 36)};
    }

    public function onClose(?e)
    {
        SceneManager.removeResizeHandler(resize);
    }

    public function new()
    {
        super();
        SceneManager.addResizeHandler(resize);
        resize();
    }
}