package gfx.popups;

import gfx.basic_components.BaseDialog;
import net.shared.utils.MathUtils;
import haxe.ui.containers.dialogs.Dialog;
import utils.Changelog;
import dict.Dictionary;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.ComponentBuilder.build('assets/layouts/popups/changelog_dialog.xml'))
class ChangelogDialog extends BaseDialog
{
    private function resize()
    {
        width = Math.min(1000, 0.9 * HaxeUIScreen.instance.actualWidth);
        height = Math.min(450, 0.7 * HaxeUIScreen.instance.actualHeight);
        changesLabel.customStyle = {fontSize: MathUtils.clamp(0.013 * HaxeUIScreen.instance.actualHeight, 12, 36)};
    }

    private function onClose(btn)
    {
        //* Do nothing
    }

    public function new()
    {
        super(null, false);
    }
}