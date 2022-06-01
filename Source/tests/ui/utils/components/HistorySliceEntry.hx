package tests.ui.utils.components;

import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/historysliceentry.xml"))
class HistorySliceEntry extends HBox
{
    public function new(dropBeforeCallback:Void->Void, dropThisCallback:Void->Void, dropAfterCallback:Void->Void) 
    {
        super();
        dropBeforeBtn.onClick = e -> {dropBeforeCallback();};
        dropThisBtn.onClick = e -> {dropThisCallback();};
        dropAfterBtn.onClick = e -> {dropAfterCallback();};
    }
}