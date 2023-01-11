package gfx.main;

import dict.Dictionary;
import haxe.ui.tooltips.ToolTipManager;
import gfx.common.SituationTooltipRenderer;
import assets.Paths;
import net.shared.PieceColor;
import utils.TimeControl;
import haxe.ui.core.ItemRenderer;
import net.shared.board.Situation;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main_menu/renderers/challenge_mode_renderer.xml"))
class ChallengeModeRenderer extends ItemRenderer
{
    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        if (data != null && data.mode != null) 
        {
            var color:Null<PieceColor> = data.mode.color;
            var customStartingSituation:Null<Situation> = data.mode.situation;
            colorIcon.resource = Paths.challengeColor(color);
            colorIcon.tooltip = Dictionary.getPhrase(CHALLENGE_COLOR_ICON_TOOLTIP(color));
            if (customStartingSituation != null)
            {
                customStartPosIcon.hidden = false;
                var renderer:SituationTooltipRenderer = new SituationTooltipRenderer(customStartingSituation);
                ToolTipManager.instance.registerTooltip(customStartPosIcon, {
                    renderer: renderer
                });
            }
            else
                customStartPosIcon.hidden = true;
        }
    }
}