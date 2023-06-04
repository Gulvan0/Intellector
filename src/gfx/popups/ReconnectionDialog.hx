package gfx.popups;

import dict.Dictionary;
import gfx.basic_components.BaseDialog;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/popups/reconnection_dialog.xml'))
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
    }
}