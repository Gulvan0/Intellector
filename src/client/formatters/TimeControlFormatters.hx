package client.formatters;

import haxefolio.LocaleUtils;
import client.datatypes.TimeControl;
import client.datatypes.FischerTimeControl;

class TimeControlFormatters
{
    public static function formatFischerTimeControl(timeControl:FischerTimeControl):String
    {
        var startSecondsRemainder:Int = timeControl.startSeconds % 60;
        var startMinutes:Int = Math.floor(timeControl.startSeconds / 60);
        var startMinutesRemainder:Int = startMinutes % 60;
        var startHours:Int = Math.floor(startMinutes / 60);

        var startComponent:String = "";
        if (startSecondsRemainder == 0 && startHours == 0)
            startComponent = Std.string(startMinutes);
        else
        {
            if (startHours != 0)
                startComponent += '${startHours}h';
            if (startMinutesRemainder != 0)
                startComponent += '${startMinutesRemainder}m';
            if (startSecondsRemainder != 0)
                startComponent += '${startSecondsRemainder}s';
        }

        return '$startComponent+${timeControl.incrementSeconds}';
    }

    public static function formatTimeControl(timeControl:TimeControl):String
    {
        return switch timeControl
        {
            case None: LocaleUtils.localeBinding("intellector.common.correspondence_time_control_name");
            case Fischer(instance): formatFischerTimeControl(instance);
        }
    }
}
