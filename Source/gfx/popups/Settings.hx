package gfx.popups;

import haxe.ui.containers.dialogs.Dialog;
import Preferences.Markup;
import Preferences.BranchingTabType;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/settings_popup.xml'))
class Settings extends Dialog
{
    public function new()
    {
        super();
        
    }
}