package gfx.main;

import utils.AssetManager;
import utils.TimeControl;
import haxe.ui.core.ItemRenderer;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/renderers/time_control_renderer.xml"))
class TimeControlRenderer extends ItemRenderer
{
    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        if (data != null) 
        {
            var timeControl:TimeControl = data.timeControl;
            var timeControlType:TimeControlType = timeControl.getType();

            tcIcon.resource = AssetManager.timeControlPath(timeControlType);
            tcIcon.text = timeControlType.getName();

            tcLabel.text = timeControl.toString();
        }
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        tcLabel.customStyle = {fontSize: height / 1.5};
        return b;
    }
}