package gfx.analysis;

import gfx.common.ShareDialog;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;

enum BtnPressEvent
{
    ChangeOrientation;
    EditPosition;
    Share;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/analysis/action_bar.xml"))
class AnalysisActionBar extends VBox
{
    public var btnCallback:BtnPressEvent->Void;

    @:bind(changeOrientationBtn, MouseEvent.CLICK)
    private function onChangeOrientationPressed(e)
    {
        btnCallback(ChangeOrientation);
    }

    @:bind(editPositionBtn, MouseEvent.CLICK)
    private function onEditPositionPressed(e)
    {
        btnCallback(EditPosition);
    }
    
    @:bind(shareBtn, MouseEvent.CLICK)
    private function onSharePressed(e)
    {
        btnCallback(Share);
    }

    public function new() 
    {
        super();    
    }
}