package tests.ui.utils.components;

import gfx.Dialogs;
import haxe.ui.events.MouseEvent;
import tests.ui.utils.data.Macro;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/testenv/proposemacrosdialog.xml"))
class ProposeMacrosDialog extends Dialog 
{
    private var excludedMacros:Array<String>;
    private final totalPending:Int;

    private function onMacroExcluded(name:String) 
    {
        excludedMacros.push(name);
    }

    private function onMacroIncluded(name:String) 
    {
        excludedMacros.remove(name);
    }

    public function new(macroNames:Array<String>) 
    {
        super();
        this.excludedMacros = [];
        this.totalPending = macroNames.length;

        for (macroName in macroNames)
        {
            var includeCallback:Void->Void = onMacroIncluded.bind(macroName);
            var excludeCallback:Void->Void = onMacroExcluded.bind(macroName);
            var macroEntry:MacroListEntry = new MacroListEntry(macroName, includeCallback, excludeCallback);
            macrolistVBox.addComponent(macroEntry);
        }

        buttons = DialogButton.APPLY;

        onDialogClosed = e -> {
            if (e.button == DialogButton.APPLY)
                if (excludedMacros.length < totalPending)
                    DataKeeper.proposeMacros(excludedMacros);
        };
    }
}