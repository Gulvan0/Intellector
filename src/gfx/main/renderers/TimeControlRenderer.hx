package gfx.main.renderers;

import dict.Utils;
import dict.Dictionary;
import assets.Paths;
import net.shared.TimeControl;
import haxe.ui.core.ItemRenderer;
import net.shared.TimeControlType;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main/renderers/time_control_renderer.xml"))
class TimeControlRenderer extends ItemRenderer
{
    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        if (data != null) 
        {
            var timeControl:TimeControl = data.timeControl;
            var timeControlType:TimeControlType = timeControl.getType();

            tcIcon.resource = Paths.timeControl(timeControlType);
            tcIcon.text = Utils.getTimeControlTypeName(timeControlType);

            tcLabel.text = timeControl.toString();
        }
    }
}