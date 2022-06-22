package tests.ui.utils.components;

import gfx.components.Dialogs;
import tests.ui.utils.data.Macro;
import tests.ui.utils.data.MacroStep;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/addmacrodialog.xml"))
class AddMacroDialog extends Dialog
{
    private var entryIDs:Array<Int>;
    private var historySlice:Array<MacroStep>;

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
        var totalElementsToRemove:Int = entryIDs.length - index - 1;

        entryIDs = entryIDs.slice(0, index+1);
        historySlice = historySlice.slice(0, index+1);
        for (i in 0...totalElementsToRemove)
            historyVBox.removeComponentAt(index+1);
    }

    private function checkHistorySliceConsistensy():HistorySliceState
    {
        for (step in historySlice.slice(1))
        {
            switch step {
                case Initialization(_):
                    return NotLeadingInit;
                default:
            }
        }
        return Consistent; //Doesn't check for InterruptedSequence inconsistensy yet
    }

    private static function addMacro(name:String, historySlice:Array<MacroStep>, onMacroAdded:Macro->Void)
    {
        var m:Macro = new Macro(name, historySlice);
        DataKeeper.getCurrent().descriptor.addMacro(m);
        onMacroAdded(m);
    }

    public function new(onMacroAdded:Macro->Void)
    {
        super();
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
                if (nameInputField.text == "")
                    Dialogs.alert("Failed to add macro: name not specified", "TestEnv Warning");
                else if (DataKeeper.getAllMacroNames().contains(nameInputField.text))
                    Dialogs.alert("Failed to add macro: a macro with this name already exists", "TestEnv Warning");
                else
                {
                    var historySliceState = checkHistorySliceConsistensy();
                    if (historySliceState != Consistent)
                        Dialogs.confirm("Slice is inconsistent: " + historySliceState.getName() + ", save macro anyway?", "Warning: Inconsistensy Detected", addMacro.bind(nameInputField.text, historySlice, onMacroAdded), ()->{});
                    else
                        addMacro(nameInputField.text, historySlice, onMacroAdded);
                }
        };
    }    
}