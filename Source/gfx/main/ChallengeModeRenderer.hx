package gfx.main;

import utils.AssetManager;
import struct.PieceColor;
import utils.TimeControl;
import haxe.ui.core.ItemRenderer;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/renderers/challenge_mode_renderer.xml"))
class ChallengeModeRenderer extends ItemRenderer
{
    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        if (data != null) 
        {
            var color:Null<PieceColor> = data.ownerOpponentColor;
            var timeControlType:TimeControlType = new TimeControl(data.startSecs, data.bonusSecs).getType();
            timeControlIcon.resource = AssetManager.timeControlPath(timeControlType);
            timeControlIcon.tooltip = timeControlType.getName();
            colorIcon.resource = AssetManager.challengeColorPath(color);
            //TODO: Dict for colorIcon tooltip
        }
    }
}