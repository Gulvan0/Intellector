package tests.ui.utils.components;

import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/testenv/historysliceentry.xml"))
class HistorySliceEntry extends HBox
{
    public function new(stepName:String, dropBeforeCallback:Void->Void, dropThisCallback:Void->Void, dropAfterCallback:Void->Void) 
    {
        super();
        stepLabel.text = stepName;
        dropBeforeBtn.onClick = e -> {dropBeforeCallback();};
        dropThisBtn.onClick = e -> {dropThisCallback();};
        dropAfterBtn.onClick = e -> {dropAfterCallback();};
    }
}