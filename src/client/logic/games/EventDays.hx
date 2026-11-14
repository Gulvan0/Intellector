package client.logic.games;

import client.datatypes.games.EventDay;
import client.datatypes.games.LocalDateTime;
import haxe.Resource;
import jsonmodel.UnserializableArray;
import jsonmodel.UnserializerInput;
import net.models.game.archive.EventDayRecord;

class EventDays
{
    private static var cached:Null<Array<EventDay>> = null;

    /** The embedded `event_days.json`, in its order **/
    public static function all():Array<EventDay>
    {
        if (cached == null)
        {
            var records:UnserializableArray<EventDayRecord> = new UnserializableArray(UnserializerInput.Str(Resource.getString("event_days")));
            cached = records.parsed.map(recordToDatatype);
        }
        return cached;
    }

    private static function recordToDatatype(record:EventDayRecord):EventDay
    {
        var dateParts:Array<Null<Int>> = record.date.split("-").map(Std.parseInt);
        if (dateParts.length != 3 || dateParts.contains(null))
            throw 'Event day date must look like yyyy-mm-dd, got "${record.date}"';

        var names:Map<String, String> = ["en" => record.name.en];
        if (record.name.ru != null)
            names["ru"] = record.name.ru;
        return new EventDay(new LocalDateTime(dateParts[0], dateParts[1], dateParts[2]), names);
    }
}
