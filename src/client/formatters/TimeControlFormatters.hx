package client.formatters;

import haxefolio.LocaleUtils;
import client.datatypes.timecontrol.TimeControl;
import client.datatypes.timecontrol.FischerTimeControl;

class TimeControlFormatters
{
    private static inline final HOURS_FORMAT_THRESHOLD_MINUTES:Int = 100;

    public static function formatFischerTimeControl(timeControl:FischerTimeControl):String
    {
        var startSecondsRemainder:Int = timeControl.startSeconds % 60;
        var startMinutes:Int = Math.floor(timeControl.startSeconds / 60);
        var startMinutesRemainder:Int = startMinutes % 60;
        var startHours:Int = Math.floor(startMinutes / 60);

        var startComponent:String = "";
        if (startMinutes < HOURS_FORMAT_THRESHOLD_MINUTES)
        {
            if (startSecondsRemainder == 0)
                startComponent = Std.string(startMinutes);
            else
            {
                if (startMinutes != 0)
                    startComponent += '${startMinutes}m';
                startComponent += '${startSecondsRemainder}s';
            }
        }
        else
        {
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
