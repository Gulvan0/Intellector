package client.ui.common.notifications.challenges;

import client.datatypes.TimeControl;
import client.datatypes.TimeControlKind;
import client.formatters.TimeControlFormatters;
import client.ui.Assets;
import haxe.ui.containers.HBox;

using client.ui.ComponentExtension;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/time_control_tag.xml"))
class TimeControlTag extends HBox
{
    public var compact(default, set):Bool = false;

    public function new()
    {
        super();
    }

    public function setTimeControl(timeControl:TimeControl, kind:TimeControlKind):Void
    {
        kindIcon.resource = Assets.timeControlKindIcon(kind);
        valueLabel.text = TimeControlFormatters.formatTimeControl(timeControl);

        var isWord:Bool = timeControl.match(None);
        valueLabel.setClass(StyleClass.CHALLENGE_TIME_WORD, isWord);
        valueLabel.setClass(StyleClass.CHALLENGE_TIME_VALUE, !isWord);
    }

    private function set_compact(value:Bool):Bool
    {
        compact = value;
        valueLabel.setClass(StyleClass.CHALLENGE_TIME_COMPACT, value);
        return value;
    }
}
