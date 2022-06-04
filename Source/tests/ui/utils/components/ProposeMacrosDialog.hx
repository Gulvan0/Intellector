package tests.ui.utils.components;

import haxe.ui.events.MouseEvent;
import tests.ui.utils.data.Macro;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/proposemacrosdialog.xml"))
class ProposeMacrosDialog extends Dialog 
{
    private var excludedMacros:Array<String>;

    private function onMacroExcluded(name:String) 
    {
        excludedMacros.push(name);
    }

    private function onMacroIncluded(name:String) 
    {
        excludedMacros.remove(name);
    }

    @:bind(confirmBtn, MouseEvent.CLICK)
    private function onConfirmBtnPressed(e) 
    {
        DataKeeper.proposeMacros(excludedMacros);
        hideDialog(DialogButton.APPLY);
    }

    public function new(macroNames:Array<String>) 
    {
        super();
        this.excludedMacros = [];

        for (macroName in macroNames)
        {
            var includeCallback:Void->Void = onMacroIncluded.bind(macroName);
            var excludeCallback:Void->Void = onMacroExcluded.bind(macroName);
            var macroEntry:MacroListEntry = new MacroListEntry(macroName, includeCallback, excludeCallback);
            macrolistVBox.addComponent(macroEntry);
        }
    }
}