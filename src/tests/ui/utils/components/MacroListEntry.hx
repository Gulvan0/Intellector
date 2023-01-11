package tests.ui.utils.components;

import haxe.ui.events.MouseEvent;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/testenv/macrolistentry.xml"))
class MacroListEntry extends HBox
{
    private var includeCallback:Void->Void;
    private var excludeCallback:Void->Void;

    @:bind(excludeBtn, MouseEvent.CLICK)
    private function exclude(e)
    {
        excludeBtn.hidden = true;
        includeBtn.hidden = false;
        macroNameLabel.customStyle = {fontSize: 25, color: 0xAAAAAA};
        excludeCallback();
    }

    @:bind(includeBtn, MouseEvent.CLICK)
    private function include(e)
    {
        excludeBtn.hidden = false;
        includeBtn.hidden = true;
        macroNameLabel.customStyle = {fontSize: 25, color: 0x333333};
        includeCallback();
    }

    public function new(macroName:String, includeCallback:Void->Void, excludeCallback:Void->Void)
    {
        super();
        this.includeCallback = includeCallback;
        this.excludeCallback = excludeCallback;

        macroNameLabel.text = macroName;
    }
}