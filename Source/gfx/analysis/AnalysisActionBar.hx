package gfx.analysis;

import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/analysis/action_bar.xml"))
class AnalysisActionBar extends VBox
{
    public var eventHandler:PeripheralEvent->Void;

    public function handlePeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case ApplyChangesRequested(turnColor):
                hidden = false;
            case DiscardChangesRequested:
                hidden = false;
            case EditorLaunchRequested:
                hidden = true;
            default:
        }
    }

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