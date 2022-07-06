package gfx.analysis;

import gfx.common.ShareDialog;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/analysis/action_bar.xml"))
class AnalysisActionBar extends VBox
{
    public var eventHandler:PeripheralEvent->Void;

    @:bind(changeOrientationBtn, MouseEvent.CLICK)
    private function onChangeOrientationPressed(e)
    {
        eventHandler(OrientationChangeRequested);
    }

    @:bind(editPositionBtn, MouseEvent.CLICK)
    private function onEditPositionPressed(e)
    {
        eventHandler(EditorLaunchRequested);
    }
    
    @:bind(shareBtn, MouseEvent.CLICK)
    private function onSharePressed(e)
    {
        eventHandler(ShareRequested);
    }

    public function new() 
    {
        super();    
    }
}