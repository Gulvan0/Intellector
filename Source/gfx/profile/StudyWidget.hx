package gfx.profile;

import haxe.ui.events.MouseEvent;
import haxe.ui.core.ItemRenderer;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/study_widget.xml"))
class StudyWidget extends ItemRenderer
{
    private var studyID:Int;
    
    @:bind(editBtn, MouseEvent.CLICK)
    private function edit(e)
    {
        //TODO: Fill
    }

    @:bind(deleteBtn, MouseEvent.CLICK)
    private function delete(e)
    {
        //TODO: Fill
    }

    private override function onDataChanged(data:Dynamic)
    {
        //TODO: Fill
    }
}