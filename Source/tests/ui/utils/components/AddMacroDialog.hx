package tests.ui.utils.components;

import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/addmacrodialog.xml"))
class AddMacroDialog extends Dialog
{
    public function new() //TODO: In what format should history entries arrive?
    {
        super();
        //TODO: Fill
    }    
}