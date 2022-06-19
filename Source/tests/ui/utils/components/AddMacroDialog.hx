package tests.ui.utils.components;

import tests.ui.utils.data.Macro;
import tests.ui.utils.data.MacroStep;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/addmacrodialog.xml"))
class AddMacroDialog extends Dialog
{
    private var entryIDs:Array<Int>;
    private var historySlice:Array<MacroStep>;

    private var onConfirmed:Macro->Void;

    private function onDropBefore(id:Int)
    {
        var index:Int = entryIDs.indexOf(id);
        entryIDs.splice(0, index);
        historySlice.splice(0, index);
        for (i in 0...index)
            historyVBox.removeComponentAt(0);
    }

    private function onDropOne(id:Int)
    {
        var index:Int = entryIDs.indexOf(id);
        entryIDs.splice(index, 1);
        historySlice.splice(index, 1);
        historyVBox.removeComponentAt(index);
    }
    
    private function onDropAfter(id:Int)
    {
        var index:Int = entryIDs.indexOf(id);
        entryIDs = entryIDs.slice(0, index+1);
        historySlice = historySlice.slice(0, index+1);
        for (i in (index+1)...entryIDs.length)
            historyVBox.removeComponentAt(index+1);
    }

    public function new(onConfirmed:Macro->Void)
    {
        super();
        this.onConfirmed = onConfirmed;
        this.entryIDs = [];
        this.historySlice = UITest.getHistory();

        for (i => macroStep in historySlice.keyValueIterator())
        {
            var stepName:String = macroStepDisplayText(macroStep);
            var entry:HistorySliceEntry = new HistorySliceEntry(stepName, onDropBefore.bind(i), onDropOne.bind(i), onDropAfter.bind(i));
            entryIDs.push(i);
            historyVBox.addComponent(entry);
        }

        buttons = DialogButton.APPLY;

        onDialogClosed = e -> {
            if (e.button == DialogButton.APPLY)
                if (nameInputField.text != "")
                    onConfirmed(new Macro(nameInputField.text, historySlice));
                else 
                    trace("Failed to add macro: name not specified");
        };
    }    
}