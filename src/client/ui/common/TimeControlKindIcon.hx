package client.ui.common;

import client.datatypes.timecontrol.TimeControlKind;
import haxe.ui.components.Image;
import haxefolio.LocaleUtils;

/** A time control kind's icon, `size` px square, naming the kind in its tooltip **/
class TimeControlKindIcon extends Image
{
    public function new(kind:TimeControlKind, size:Int = 16)
    {
        super();
        width = size;
        height = size;
        scaleMode = "fitinside";
        verticalAlign = "center";
        setKind(kind);
    }

    public function setKind(kind:TimeControlKind):Void
    {
        resource = Assets.timeControlKindIcon(kind);
        tooltip = LocaleUtils.localeBinding('intellector.common.time_control_kind.${kind.getName().toLowerCase()}');
    }
}
