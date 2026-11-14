package net.models.game.archive;

import jsonmodel.IJsonUnserializableMacro;
import net.models.changelog.LocalizedTextRecord;

/** An entry of the embedded `event_days.json` **/
class EventDayRecord implements IJsonUnserializableMacro
{
    /** `yyyy-mm-dd` **/
    public var date:String;
    public var name:LocalizedTextRecord;
}
