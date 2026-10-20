package client.ui.common.overlays.share;

import client.datatypes.share.ExportKind;
import haxefolio.appearance.AppearanceContext;

/**
    The share pages' heights, summed from the sizes they are built with rather than measured, so the
    frame can be declared before anything is laid out.
**/
class ShareLayout
{
    /** The settings column of an export panel, its controls `fieldHeight` tall **/
    public static function settingsHeight(kind:ExportKind, fieldHeight:Int):Int
    {
        var labelled:Int = labelledHeight(fieldHeight);

        return switch kind {
            case Image: 3 * StyleVars.SHARE_PANEL_GAP + 2 * labelled + labelledHeight(2 * fieldHeight) + fieldHeight;
            case Animation: 4 * StyleVars.SHARE_PANEL_GAP + 4 * labelled + fieldHeight;
        }
    }

    /** Share position: the SIP and the image panel **/
    public static function positionPageHeight(fieldHeight:Int):Int
    {
        return 2 * StyleVars.SHARE_BODY_PADDING_VERTICAL
            + labelledHeight(fieldHeight)
            + StyleVars.SHARE_SECTION_GAP
            + panelSectionHeight(Image, fieldHeight);
    }

    /** Share game: the link, the PIN and the animation panel **/
    public static function gamePageHeight(fieldHeight:Int):Int
    {
        return 2 * StyleVars.SHARE_BODY_PADDING_VERTICAL
            + labelledHeight(fieldHeight)
            + StyleVars.SHARE_SECTION_GAP
            + labelledHeight(StyleVars.SHARE_PIN_HEIGHT)
            + StyleVars.SHARE_SECTION_GAP
            + panelSectionHeight(Animation, fieldHeight);
    }

    private static function panelSectionHeight(kind:ExportKind, fieldHeight:Int):Int
    {
        return labelledHeight(2 * StyleVars.SHARE_PANEL_PADDING + settingsHeight(kind, fieldHeight));
    }

    // a control under its label line
    private static function labelledHeight(controlHeight:Int):Int
    {
        return AppearanceContext.current.geometry.messageLine + StyleVars.SHARE_LABEL_GAP + controlHeight;
    }
}
